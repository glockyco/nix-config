#!/usr/bin/env python3
"""Prepare and select verified, host-local OMP source generations."""

import argparse
import base64
from contextlib import contextmanager
import fcntl
import hashlib
import hmac
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import signal
import subprocess
import sys
import tarfile
import tempfile
import urllib.request
import uuid
from urllib.parse import quote


COMMIT = re.compile(r"[0-9a-f]{40}\Z")
RELEASE = re.compile(r"v?(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\Z")
SYSTEMS = {"aarch64-darwin", "x86_64-linux"}
PHASES = (
    "environment",
    "dependencies",
    "native-build",
    "package-checks",
    "patch-regressions",
    "native-load",
    "cli-smoke",
)
REGRESSIONS = (
    "packages/utils/test/marked.test.ts",
    "packages/tui/test/markdown.test.ts",
    "packages/tui/test/terminal-capabilities.test.ts",
    "packages/coding-agent/test/tui/hyperlink.test.ts",
    "packages/coding-agent/test/tools/read-renderer.test.ts",
    "packages/coding-agent/test/read-tool-group.test.ts",
    "packages/coding-agent/test/tools/grep-renderer.test.ts",
    "packages/coding-agent/test/tools/tool-output-hyperlinks.test.ts",
    "packages/coding-agent/test/tools/image-gen.test.ts",
    "packages/coding-agent/test/tools/image-gen-renderer.test.ts",
)


NATIVE_SOURCES = (
    "crates/",
    "packages/natives/",
    "bazel/",
    ".bazelrc",
    "BUILD.bazel",
    "MODULE.bazel",
    "MODULE.bazel.lock",
    "Cargo.toml",
    "Cargo.lock",
    "rust-toolchain.toml",
)
NATIVE_REGISTRY = "https://registry.npmjs.org"
NATIVE_PACKAGE = "@oh-my-pi/pi-natives"
NATIVE_PREDICATE = "https://slsa.dev/provenance/v1"
NATIVE_TIMEOUT = 300


class UpdateError(Exception):
    pass


def native_sources_changed(paths):
    """Report whether a changed path set contains a native build input."""
    for path in paths:
        for source in NATIVE_SOURCES:
            if path == source or (source.endswith("/") and path.startswith(source)):
                return True
    return False


def host_avx2():
    """Report AVX2 support for the x86-64 addon variant, as upstream detects it."""
    try:
        info = Path("/proc/cpuinfo").read_text(encoding="utf-8", errors="replace")
    except OSError:
        return False
    return bool(re.search(r"\bavx2\b", info, re.IGNORECASE))


def addon_identity(system):
    """Resolve the upstream addon target, published platform package, and filename."""
    if system == "aarch64-darwin":
        target, leaf = "darwin-arm64", "darwin-arm64"
    elif system == "x86_64-linux":
        target = "linux-x64-modern" if host_avx2() else "linux-x64-baseline"
        leaf = "linux-x64"
    else:
        raise UpdateError(f"No published addon target for {system}")
    return target, f"{NATIVE_PACKAGE}-{leaf}", f"pi_natives.{target}.node"


def fetch_json(url):
    with urllib.request.urlopen(url, timeout=NATIVE_TIMEOUT) as response:
        return json.load(response)


def download(url, path):
    """Store a registry artifact and return its Subresource Integrity digest."""
    if not url.startswith(f"{NATIVE_REGISTRY}/"):
        raise UpdateError(f"Published artifact is outside the registry: {url}")
    digest = hashlib.sha512()
    with urllib.request.urlopen(url, timeout=NATIVE_TIMEOUT) as response:
        with path.open("wb") as artifact:
            while chunk := response.read(1 << 20):
                digest.update(chunk)
                artifact.write(chunk)
    return "sha512-" + base64.b64encode(digest.digest()).decode("ascii")


def verify_integrity(observed, published):
    if not isinstance(published, str) or not published.startswith("sha512-"):
        raise UpdateError("The registry published no sha512 integrity digest")
    if not hmac.compare_digest(observed, published):
        raise UpdateError("The published addon does not match its integrity digest")


def read_json(path):
    with path.open(encoding="utf-8") as source:
        return json.load(source)


def validate_metadata(data):
    fields = {"release", "upstream", "patchBase", "patchTip", "commit", "system"}
    if not isinstance(data, dict) or set(data) != fields:
        raise UpdateError("Invalid generation metadata fields")
    if not isinstance(data["release"], str) or not RELEASE.fullmatch(data["release"]):
        raise UpdateError("Invalid stable release tag")
    for field in ("upstream", "patchBase", "patchTip", "commit"):
        if not isinstance(data[field], str) or not COMMIT.fullmatch(data[field]):
            raise UpdateError(f"Invalid {field} commit")
    if not isinstance(data["system"], str) or data["system"] not in SYSTEMS:
        raise UpdateError("Unsupported generation system")
    return data


def load_config(path):
    data = read_json(path)
    fields = {
        "upstreamUrl",
        "githubRepo",
        "patchUrl",
        "patchBase",
        "patchTip",
        "system",
        "plugin",
        "git",
        "gh",
        "nix",
        "nixStore",
        "nixPackage",
    }
    if not isinstance(data, dict) or set(data) != fields:
        raise UpdateError("Invalid updater configuration fields")
    if not all(
        isinstance(value, str) and "\x00" not in value and "\n" not in value
        for value in data.values()
    ):
        raise UpdateError("Invalid updater configuration value")
    for field in ("patchBase", "patchTip"):
        if not COMMIT.fullmatch(data[field]):
            raise UpdateError(f"Invalid pinned {field}")
    if data["system"] not in SYSTEMS:
        raise UpdateError("Unsupported updater system")
    if not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", data["githubRepo"]):
        raise UpdateError("Invalid GitHub repository")
    for field in ("upstreamUrl", "patchUrl"):
        if not data[field].startswith(("https://", "/")):
            raise UpdateError(f"Invalid {field}")
    for field in ("plugin", "git", "gh", "nix", "nixStore"):
        if not Path(data[field]).is_absolute():
            raise UpdateError(f"Expected an absolute {field} path")
    if data["system"] == "x86_64-linux" and not data["nixPackage"].startswith(
        "/nix/store/"
    ):
        raise UpdateError("Expected a Nix store package for the Linux launcher")
    return data


class Updater:
    def __init__(self, config, home=None, release_provider=None, prepare_phase=None):
        self.config = config
        self.home = Path(home if home is not None else os.environ["HOME"]).resolve(
            strict=True
        )
        self.root = self.home / ".local/share/omp-dev"
        self.generations = self.root / "generations"
        self.repo = self.root / "repository.git"
        self.phase = "initialization"
        self.candidate = None
        self.lock_fd = None
        self.release_provider = release_provider or self.latest_release
        self.prepare_phase = prepare_phase or self.prepare
        self.env = os.environ.copy()
        for key in tuple(self.env):
            if key.startswith("GIT_"):
                self.env.pop(key)
        self.env.update(
            {
                "GIT_CONFIG_NOSYSTEM": "1",
                "GIT_CONFIG_GLOBAL": os.devnull,
                "GIT_TERMINAL_PROMPT": "0",
                "GIT_AUTHOR_NAME": "OMP source updater",
                "GIT_AUTHOR_EMAIL": "omp-dev-update@localhost",
                "GIT_COMMITTER_NAME": "OMP source updater",
                "GIT_COMMITTER_EMAIL": "omp-dev-update@localhost",
            }
        )

    def run(self, args, cwd=None, env=None, capture=False, timeout=None):
        process = subprocess.Popen(
            [str(arg) for arg in args],
            cwd=cwd,
            env=self.env if env is None else env,
            stdout=subprocess.PIPE if capture else None,
            text=True,
            start_new_session=True,
            pass_fds=() if self.lock_fd is None else (self.lock_fd,),
        )
        try:
            stdout, _ = process.communicate(timeout=timeout)
        except BaseException:
            try:
                os.killpg(process.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait()
            raise
        if process.returncode:
            raise UpdateError(
                f"Command exited {process.returncode}: {shlex.join(str(arg) for arg in args)}"
            )
        return (stdout or "").strip()

    def git(self, *args, checkout=None, capture=True):
        location = ["--git-dir", self.repo] if checkout is None else ["-C", checkout]
        return self.run(
            [
                self.config["git"],
                "-c",
                "core.hooksPath=/dev/null",
                "-c",
                "commit.gpgSign=false",
                "-c",
                "core.autocrlf=false",
                *location,
                *args,
            ],
            capture=capture,
        )

    def set_phase(self, phase):
        self.phase = phase
        candidate = f"; candidate: {self.candidate}" if self.candidate else ""
        print(f"omp-dev-update: {phase}{candidate}", file=sys.stderr, flush=True)

    def check_root(self, create=False):
        if self.root.resolve() != self.root:
            raise UpdateError(f"State path contains a symlink: {self.root}")
        if create:
            self.root.mkdir(parents=True, exist_ok=True, mode=0o700)
        for path in (self.generations, self.repo):
            if path.is_symlink() or (path.exists() and not path.is_dir()):
                raise UpdateError(f"Invalid state directory: {path}")

    @contextmanager
    def locked(self):
        self.check_root(create=True)
        descriptor = os.open(
            self.root / "update.lock", os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600
        )
        try:
            try:
                fcntl.flock(descriptor, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError as error:
                raise UpdateError(
                    "Another update or rollback holds the update lock"
                ) from error
            self.lock_fd = descriptor
            self.recover_promotion()
            yield
        finally:
            self.lock_fd = None
            os.close(descriptor)

    def generation_path(self, relative):
        if not isinstance(relative, str):
            raise UpdateError("Invalid generation target")
        parts = Path(relative).parts
        if (
            len(parts) != 2
            or parts[0] != "generations"
            or not re.fullmatch(r"[A-Za-z0-9._-]+", parts[1])
        ):
            raise UpdateError(f"Invalid generation target: {relative}")
        path = self.root / relative
        if path.resolve() != path or not path.is_dir():
            raise UpdateError(f"Generation target escapes or is absent: {path}")
        return path

    def link_target(self, name):
        path = self.root / name
        if not path.is_symlink():
            if path.exists():
                raise UpdateError(f"Expected a generation symlink: {path}")
            return None
        relative = os.readlink(path)
        self.generation_path(relative)
        return relative

    def generation_metadata(self, relative, verify_checkout=True):
        generation = self.generation_path(relative)
        for name in ("checkout", "generation.json", "omp"):
            path = generation / name
            if path.is_symlink() or not path.exists():
                raise UpdateError(f"Invalid generation path: {path}")
        if not (generation / "checkout").is_dir() or not os.access(
            generation / "omp", os.X_OK
        ):
            raise UpdateError(f"Generation is not executable: {generation}")
        profile = generation / "dev-profile"
        if (
            not profile.is_symlink()
            or not profile.exists()
            or not str(profile.resolve()).startswith("/nix/store/")
        ):
            raise UpdateError(
                f"Retained development profile is absent or invalid: {profile}"
            )
        metadata = validate_metadata(read_json(generation / "generation.json"))
        if metadata["system"] != self.config["system"]:
            raise UpdateError(
                f"Generation system does not match {self.config['system']}"
            )
        if verify_checkout:
            checkout = generation / "checkout"
            common = Path(
                self.git(
                    "rev-parse",
                    "--path-format=absolute",
                    "--git-common-dir",
                    checkout=checkout,
                )
            )
            if (
                common.resolve() != self.repo
                or self.git("rev-parse", "HEAD", checkout=checkout)
                != metadata["commit"]
            ):
                raise UpdateError(
                    f"Generation checkout does not match its metadata: {generation}"
                )
        return metadata

    def status(self):
        self.check_root()
        current = self.link_target("current")
        if current is None:
            raise UpdateError(
                f"No selected generation at {self.root / 'current'}; run omp-dev-update"
            )
        return self.generation_metadata(current, verify_checkout=False)

    def api(self, endpoint):
        return json.loads(
            self.run(
                [
                    self.config["gh"],
                    "api",
                    f"repos/{self.config['githubRepo']}/{endpoint}",
                ],
                capture=True,
            )
        )

    def latest_release(self):
        data = self.api("releases/latest")
        if (
            not isinstance(data, dict)
            or data.get("draft") is not False
            or data.get("prerelease") is not False
        ):
            raise UpdateError("GitHub did not return a stable release")
        tag = data.get("tag_name")
        if not isinstance(tag, str) or not RELEASE.fullmatch(tag):
            raise UpdateError("GitHub returned an invalid stable release tag")
        commit_data = self.api(f"commits/{quote(tag, safe='')}")
        commit = commit_data.get("sha") if isinstance(commit_data, dict) else None
        if not isinstance(commit, str) or not COMMIT.fullmatch(commit):
            raise UpdateError("GitHub returned an invalid release commit")
        return tag, commit

    def fetch_inputs(self):
        tag, upstream = self.release_provider()
        metadata = validate_metadata(
            {
                "release": tag,
                "upstream": upstream,
                "patchBase": self.config["patchBase"],
                "patchTip": self.config["patchTip"],
                "commit": upstream,
                "system": self.config["system"],
            }
        )
        if not self.repo.exists():
            self.run([self.config["git"], "init", "--bare", self.repo])
        if self.git("rev-parse", "--is-bare-repository") != "true":
            raise UpdateError("The shared repository is not bare")
        self.git(
            "fetch",
            "--no-tags",
            self.config["upstreamUrl"],
            f"+refs/tags/{tag}:refs/omp/upstream",
            capture=False,
        )
        if self.git("rev-parse", "refs/omp/upstream^{commit}") != upstream:
            raise UpdateError(
                "The fetched release tag does not match the GitHub commit"
            )
        base, tip = metadata["patchBase"], metadata["patchTip"]
        self.git(
            "fetch", "--no-tags", self.config["patchUrl"], base, tip, capture=False
        )
        for commit in (base, tip):
            if self.git("rev-parse", f"{commit}^{{commit}}") != commit:
                raise UpdateError("A pinned patch input is not a commit")
        if base == tip:
            raise UpdateError("The pinned patch range is empty")
        self.git("merge-base", "--is-ancestor", base, tip)
        self.git("merge-base", "--is-ancestor", base, upstream)
        if self.git("rev-list", "--min-parents=2", f"{base}..{tip}"):
            raise UpdateError("The pinned patch range contains merge commits")
        return metadata

    def launcher(self, generation):
        nix = self.config["nix"]
        if self.config["system"] == "x86_64-linux":
            nix = str(generation / "nix/bin/nix")
        profile = shlex.quote(str(generation / "dev-profile"))
        upstream = shlex.quote(
            str(generation / "checkout/packages/coding-agent/scripts/omp")
        )
        launcher = generation / "omp"
        launcher.write_text(
            "#!/bin/sh\nset -eu\n"
            f"export OMP_DEV_LAUNCH_DIR={shlex.quote(str(generation / '.launch-cwd'))}\n"
            f"exec {shlex.quote(nix)} --extra-experimental-features 'nix-command flakes' develop {profile} "
            '--command sh -c \'cd -- "$1"; shift; exec "$@"\' omp "$PWD" '
            f'{upstream} "$@"\n',
            encoding="utf-8",
        )
        launcher.chmod(0o755)

    def package_cache(self):
        """Create the persistent download cache shared by every candidate."""
        cache = self.root / "cache"
        entries = {
            "BUN_INSTALL_CACHE_DIR": cache / "bun",
            "CARGO_HOME": cache / "cargo",
        }
        for path in entries.values():
            if path.is_symlink() or (path.exists() and not path.is_dir()):
                raise UpdateError(f"Invalid package cache directory: {path}")
            path.mkdir(parents=True, exist_ok=True, mode=0o700)
        return {key: str(path) for key, path in entries.items()}

    def native_component(self, generation, checkout, develop):
        """Install the published host addon, or compile it when no artifact applies."""
        changed = self.git(
            "diff", "--name-only", self.config["patchBase"], self.config["patchTip"]
        ).split("\n")
        if native_sources_changed(changed):
            print(
                "omp-dev-update: the patch range changes native sources; compiling",
                file=sys.stderr,
                flush=True,
            )
            develop("bun", "run", "build:native")
            return "compiled"
        if self.install_addon(generation, checkout, develop):
            return "installed"
        develop("bun", "run", "build:native")
        return "compiled"

    def published_addon(self, checkout):
        """Resolve the published distribution for the candidate release and host."""
        manifest = read_json(checkout / "packages/natives/package.json")
        version = manifest.get("version") if isinstance(manifest, dict) else None
        if not isinstance(version, str) or not RELEASE.fullmatch(version):
            raise UpdateError("The candidate declares an invalid native version")
        target, package, filename = addon_identity(self.config["system"])
        metadata = fetch_json(f"{NATIVE_REGISTRY}/{quote(package, safe='')}")
        versions = metadata.get("versions") if isinstance(metadata, dict) else None
        release = versions.get(version) if isinstance(versions, dict) else None
        distribution = release.get("dist") if isinstance(release, dict) else None
        if not isinstance(distribution, dict):
            print(
                f"omp-dev-update: no published {package}@{version}; compiling",
                file=sys.stderr,
                flush=True,
            )
            return None
        return target, package, filename, version, distribution

    def install_addon(self, generation, checkout, develop):
        """Verify and install the published addon; report whether it applied."""
        published = self.published_addon(checkout)
        if published is None:
            return False
        target, package, filename, version, distribution = published
        staging = Path(tempfile.mkdtemp(prefix=".native-", dir=generation))
        try:
            archive = staging / "addon.tgz"
            observed = download(distribution.get("tarball", ""), archive)
            verify_integrity(observed, distribution.get("integrity"))
            self.verify_provenance(archive, staging, package, version)
            source = staging / f"natives-{target}"
            source.mkdir()
            with tarfile.open(archive) as bundle:
                try:
                    member = bundle.getmember(f"package/{filename}")
                except KeyError:
                    print(
                        f"omp-dev-update: {package}@{version} has no {filename}; compiling",
                        file=sys.stderr,
                        flush=True,
                    )
                    return False
                if not member.isfile():
                    raise UpdateError(f"Published {filename} is not a regular file")
                with bundle.extractfile(member) as content:
                    with (source / filename).open("wb") as addon:
                        shutil.copyfileobj(content, addon)
            print(
                f"omp-dev-update: installing verified {package}@{version}",
                file=sys.stderr,
                flush=True,
            )
            develop(
                "bun",
                "scripts/bazel-natives.ts",
                "host",
                "--dest",
                "packages/natives/native",
                "--source",
                staging,
            )
            return True
        finally:
            shutil.rmtree(staging, ignore_errors=True)

    def verify_provenance(self, archive, staging, package, version):
        """Verify the published build provenance against the declared upstream."""
        attestations = fetch_json(
            f"{NATIVE_REGISTRY}/-/npm/v1/attestations/"
            f"{quote(package, safe='')}@{quote(version, safe='')}"
        )
        entries = (
            attestations.get("attestations") if isinstance(attestations, dict) else None
        )
        bundle = None
        for entry in entries or ():
            if (
                isinstance(entry, dict)
                and entry.get("predicateType") == NATIVE_PREDICATE
            ):
                bundle = entry.get("bundle")
                break
        if bundle is None:
            raise UpdateError(f"{package}@{version} publishes no build provenance")
        provenance = staging / "provenance.json"
        self.atomic_json(provenance, bundle)
        self.run(
            [
                self.config["gh"],
                "attestation",
                "verify",
                archive,
                "--bundle",
                provenance,
                "--repo",
                self.config["githubRepo"],
                "--predicate-type",
                NATIVE_PREDICATE,
                "--digest-alg",
                "sha512",
            ],
            timeout=NATIVE_TIMEOUT,
        )

    def prepare(self, phase, generation, env):
        checkout = generation / "checkout"
        nix = [
            self.config["nix"],
            "--extra-experimental-features",
            "nix-command flakes",
            "develop",
        ]
        if phase == "environment":
            if self.config["system"] == "x86_64-linux":
                self.run(
                    [
                        self.config["nixStore"],
                        "--add-root",
                        generation / "nix",
                        "--indirect",
                        "--realise",
                        self.config["nixPackage"],
                    ]
                )
            self.run(
                [
                    *nix,
                    f"path:{checkout}#devShells.{self.config['system']}.default",
                    "--no-write-lock-file",
                    "--no-update-lock-file",
                    "--profile",
                    generation / "dev-profile",
                    "--command",
                    "true",
                ],
                cwd=checkout,
            )
            return
        isolated = [
            f"{key}={env[key]}"
            for key in (
                "HOME",
                "XDG_CONFIG_HOME",
                "XDG_CACHE_HOME",
                "XDG_DATA_HOME",
                "XDG_STATE_HOME",
                "PI_CODING_AGENT_DIR",
                "OMP_AGENT_DIR",
                "OMP_DEV_LAUNCH_DIR",
                "BUN_INSTALL_CACHE_DIR",
                "CARGO_HOME",
            )
        ]

        def develop(*args, capture=False):
            return self.run(
                [
                    *nix,
                    generation / "dev-profile",
                    "--command",
                    "env",
                    *isolated,
                    *args,
                ],
                cwd=checkout,
                env=env,
                capture=capture,
            )

        if phase == "dependencies":
            develop("bun", "install", "--frozen-lockfile")
        elif phase == "native-build":
            self.native_component(generation, checkout, develop)
        elif phase == "package-checks":
            for package in ("utils", "tui", "coding-agent"):
                develop("bun", f"--cwd=packages/{package}", "run", "check")
        elif phase == "patch-regressions":
            for regression in REGRESSIONS:
                if not (checkout / regression).is_file():
                    raise UpdateError(f"Patch regression is absent: {regression}")
            develop("bun", "test", *REGRESSIONS)
        elif phase == "native-load":
            develop(
                "bun",
                "-e",
                "import {visibleWidth} from './packages/natives/native/index.js'; if (visibleWidth('OMP', 4) !== 3) throw new Error('Native width check failed');",
            )
        elif phase == "cli-smoke":
            plugin = Path(self.config["plugin"])
            for path in (
                plugin / "package.json",
                plugin / "extensions/personal-commit.ts",
                plugin / "lsp/lsp.json",
            ):
                if not path.is_file():
                    raise UpdateError(f"Immutable plugin input is absent: {path}")
            flags = ["--extension", plugin, "--plugin-dir", plugin / "lsp"]
            version = self.run(
                [generation / "omp", *flags, "--version"],
                cwd=generation / ".launch-cwd",
                env=env,
                capture=True,
                timeout=120,
            )
            if not version:
                raise UpdateError("Candidate version output is empty")
            self.run(
                [generation / "omp", *flags, "--help"],
                cwd=generation / ".launch-cwd",
                env=env,
                timeout=120,
            )
            develop(
                "bun",
                "-e",
                "import {discoverAndLoadExtensions} from './packages/coding-agent/src/extensibility/extensions/loader.ts'; "
                f"const loaded = await discoverAndLoadExtensions([{json.dumps(str(plugin))}], process.cwd(), undefined, undefined, {{ambient: false}}); "
                "if (loaded.errors.length) throw new Error(JSON.stringify(loaded.errors)); "
                "if (!loaded.extensions.some(extension => extension.tools.has('personal_commit'))) "
                "throw new Error('The immutable plugin did not register personal_commit');",
            )
        else:
            raise UpdateError(f"Unknown preparation phase: {phase}")

    def atomic_json(self, path, data):
        temporary = path.with_name(f".{path.name}-{uuid.uuid4().hex}")
        try:
            with temporary.open("x", encoding="utf-8") as output:
                json.dump(data, output, sort_keys=True)
                output.write("\n")
                output.flush()
                os.fsync(output.fileno())
            os.replace(temporary, path)
        finally:
            temporary.unlink(missing_ok=True)

    def replace_link(self, name, relative):
        path = self.root / name
        if relative is None:
            path.unlink(missing_ok=True)
            return
        self.generation_path(relative)
        temporary = self.root / f".{name}-{uuid.uuid4().hex}"
        try:
            temporary.symlink_to(relative)
            os.replace(temporary, path)
        finally:
            temporary.unlink(missing_ok=True)

    def recover_promotion(self):
        journal = self.root / "promotion.json"
        if not journal.exists() and not journal.is_symlink():
            return
        if journal.is_symlink():
            raise UpdateError("Invalid promotion journal path")
        data = read_json(journal)
        if not isinstance(data, dict) or set(data) != {"current", "previous", "next"}:
            raise UpdateError("Invalid promotion journal")
        for target in data.values():
            if target is not None:
                self.generation_metadata(target)
        if data["next"] is None:
            raise UpdateError("Invalid promotion destination")
        current = self.link_target("current")
        if current == data["next"]:
            self.replace_link("previous", data["current"])
        elif current == data["current"]:
            self.replace_link("previous", data["previous"])
        else:
            raise UpdateError("Selection does not match the interrupted promotion")
        journal.unlink()

    def promote(self, relative):
        self.generation_metadata(relative)
        before = {
            "current": self.link_target("current"),
            "previous": self.link_target("previous"),
            "next": relative,
        }
        journal = self.root / "promotion.json"
        self.atomic_json(journal, before)
        try:
            self.replace_link("previous", before["current"])
            self.replace_link("current", relative)
            journal.unlink()
        except BaseException:
            self.replace_link("current", before["current"])
            self.replace_link("previous", before["previous"])
            journal.unlink(missing_ok=True)
            raise

    def update(self):
        with self.locked():
            self.set_phase("fetch")
            metadata = self.fetch_inputs()
            current = self.link_target("current")
            if current is not None:
                selected = self.generation_metadata(current)
                if all(
                    selected[key] == value
                    for key, value in metadata.items()
                    if key != "commit"
                ):
                    print(
                        f"omp-dev-update: unchanged {self.root / current}",
                        file=sys.stderr,
                    )
                    return selected
            self.generations.mkdir(exist_ok=True)
            self.candidate = Path(
                tempfile.mkdtemp(prefix=f"{metadata['release']}-", dir=self.generations)
            )
            checkout = self.candidate / "checkout"
            self.set_phase("patch-replay")
            self.git(
                "worktree",
                "add",
                "--detach",
                checkout,
                metadata["patchTip"],
                capture=False,
            )
            self.git(
                "rebase",
                "--onto",
                metadata["upstream"],
                metadata["patchBase"],
                checkout=checkout,
                capture=False,
            )
            metadata["commit"] = self.git("rev-parse", "HEAD", checkout=checkout)
            self.git(
                "merge-base", "--is-ancestor", metadata["upstream"], metadata["commit"]
            )
            (self.candidate / ".launch-cwd").mkdir()
            self.launcher(self.candidate)
            verification_home = self.candidate / ".verification-home"
            verification_home.mkdir()
            env = self.env.copy()
            for key in tuple(env):
                if key.startswith(("PI_", "OMP_", "HERDR_")) or key in {
                    "BUN_OPTIONS",
                    "NODE_OPTIONS",
                }:
                    env.pop(key)
            env.update(
                {
                    "HOME": str(verification_home),
                    "XDG_CONFIG_HOME": str(verification_home / ".config"),
                    "XDG_CACHE_HOME": str(verification_home / ".cache"),
                    "XDG_DATA_HOME": str(verification_home / ".local/share"),
                    "XDG_STATE_HOME": str(verification_home / ".local/state"),
                    "PI_CODING_AGENT_DIR": str(verification_home / ".omp/agent"),
                    "OMP_AGENT_DIR": str(verification_home / ".omp/agent"),
                    "OMP_DEV_LAUNCH_DIR": str(self.candidate / ".launch-cwd"),
                    **self.package_cache(),
                }
            )
            for phase in PHASES:
                self.set_phase(phase)
                self.prepare_phase(phase, self.candidate, env)
            self.atomic_json(self.candidate / "generation.json", metadata)
            self.set_phase("promotion")
            self.promote(str(self.candidate.relative_to(self.root)))
            print(f"omp-dev-update: selected {self.candidate}", file=sys.stderr)
            return metadata

    def rollback(self):
        with self.locked():
            self.set_phase("rollback")
            current = self.link_target("current")
            previous = self.link_target("previous")
            if current is None or previous is None or previous == current:
                raise UpdateError("No previous generation is available for rollback")
            self.generation_metadata(current)
            metadata = self.generation_metadata(previous)
            self.promote(previous)
            print(f"omp-dev-update: selected {self.root / previous}", file=sys.stderr)
            return metadata


def interrupted(signum, _frame):
    raise InterruptedError(f"Interrupted by signal {signum}")


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Prepare and select a verified patched OMP source generation."
    )
    parser.add_argument("--config", required=True, help=argparse.SUPPRESS)
    action = parser.add_mutually_exclusive_group()
    action.add_argument(
        "--rollback",
        action="store_true",
        help="Select the previous verified generation without network access.",
    )
    action.add_argument(
        "--status",
        action="store_true",
        help="Print the selected generation metadata as JSON.",
    )
    args = parser.parse_args(argv)
    updater = None
    for signum in (signal.SIGTERM, signal.SIGHUP):
        signal.signal(signum, interrupted)
    try:
        updater = Updater(load_config(Path(args.config)))
        metadata = (
            updater.status()
            if args.status
            else updater.rollback()
            if args.rollback
            else updater.update()
        )
        print(json.dumps(metadata, sort_keys=True))
        return 0
    except (
        UpdateError,
        OSError,
        ValueError,
        KeyError,
        TypeError,
        subprocess.TimeoutExpired,
        KeyboardInterrupt,
    ) as error:
        phase = updater.phase if updater else "configuration"
        candidate = (
            updater.candidate if updater and updater.candidate else "not created"
        )
        print(
            f"omp-dev-update: failed during {phase}; candidate: {candidate}\n{error}",
            file=sys.stderr,
        )
        return 1


if __name__ == "__main__":
    sys.exit(main())
