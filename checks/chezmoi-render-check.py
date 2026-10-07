"""Exercise the tracked source, never the runner's user configuration."""

import copy
import hashlib
import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import shlex
import tempfile
import tomllib


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def snapshot(root):
    result = {}
    for path in sorted(root.rglob("*")):
        info = path.lstat()
        if path.is_symlink():
            content = os.readlink(path)
        elif path.is_file():
            content = hashlib.sha256(path.read_bytes()).hexdigest()
        else:
            content = None
        result[str(path.relative_to(root))] = (
            stat.S_IMODE(info.st_mode),
            info.st_mtime_ns,
            content,
        )
    return result


class Fixture:
    def __init__(self, source, target, resources, host, target_os, work):
        self.source = source
        self.target = target
        self.resources = resources
        self.host = host
        self.target_os = target_os
        self.work = work
        target.mkdir(parents=True)
        self.env = os.environ.copy()
        self.env.update(
            HOME=str(target),
            XDG_CONFIG_HOME=str(work / "config"),
            XDG_CACHE_HOME=str(work / "cache"),
            XDG_STATE_HOME=str(work / "state"),
            GIT_CONFIG_NOSYSTEM="1",
            GIT_CONFIG_GLOBAL=str(target / ".gitconfig"),
            PATH=os.environ["userPath"] + ":" + self.env["PATH"],
        )
        self.config = work / "chezmoi.json"
        self.config.write_text(
            json.dumps(
                {
                    "sourceDir": str(source),
                    "destDir": str(target),
                    "data": {
                        "host": host,
                        "checkMode": True,
                        "resourcesDir": str(resources),
                    },
                }
            )
        )
        self.overrides = {"chezmoi": {"os": target_os, "homeDir": str(target)}}
        self.base = [
            "chezmoi",
            "--config",
            str(self.config),
            "--source",
            str(source),
            "--destination",
            str(target),
            "--persistent-state",
            str(work / "state.boltdb"),
            "--no-tty",
            "--force",
            "--refresh-externals=never",
        ]

    def run(self, *args, overrides=None, input=None, success=True):
        data = copy.deepcopy(self.overrides)
        if overrides:
            data.update(overrides)
        process = subprocess.run(
            self.base + ["--override-data", json.dumps(data), *args],
            env=self.env,
            input=input,
            text=True,
            capture_output=True,
        )
        if success:
            require(process.returncode == 0, f"chezmoi {args}: {process.stderr}")
        else:
            require(process.returncode != 0, f"chezmoi {args} unexpectedly succeeded")
        return process.stdout

    def scripts(self, overrides=None):
        rendered = {}
        for path in sorted((self.source / "home").glob("run_*.tmpl")):
            content = self.run(
                "execute-template", input=path.read_text(), overrides=overrides
            )
            if content.strip():
                rendered[path.name] = content
        return rendered


def git_value(fixture, key, cwd=None):
    command = ["git", "config", "--get", key]
    return subprocess.check_output(command, cwd=cwd, env=fixture.env, text=True).strip()


def assert_portable(fixture, facts):
    host = facts["hosts"][fixture.host]
    platform = host["platforms"][fixture.target_os]
    require(
        git_value(fixture, "user.name") == host["git"]["authorName"],
        "shared Git author drift",
    )
    require(
        git_value(fixture, "user.email") == host["git"]["defaultEmail"],
        "shared Git email drift",
    )
    require(
        git_value(fixture, "ghq.root") == platform["ghqRoot"], "shared ghq root drift"
    )
    for key, expected in {
        "init.defaultBranch": "main",
        "pull.rebase": "true",
        "push.autoSetupRemote": "true",
        "core.autocrlf": "input",
        "filter.lfs.required": "true",
        "core.pager": "delta",
    }.items():
        require(git_value(fixture, key) == expected, f"Git {key} drift")
    shell = (fixture.target / ".zshrc").read_text()
    for setting in (
        "HISTSIZE=100000",
        "SAVEHIST=100000",
        "SHARE_HISTORY",
        "APPEND_HISTORY",
        "HIST_IGNORE_ALL_DUPS",
        "HIST_IGNORE_SPACE",
        "[[ -t 0 ]]",
        "fzf --zsh",
    ):
        require(setting in shell, f"shell contract missing {setting}")
    require(
        shell.index("[[ -t 0 ]]") < shell.index("fzf --zsh"),
        "unguarded fzf initialization",
    )
    for duplicate in (
        "zsh-autosuggestions.zsh",
        "zsh-syntax-highlighting.zsh",
        "compinit",
    ):
        require(
            duplicate not in shell, f"user shell duplicates native plugin {duplicate}"
        )
    starship = tomllib.loads((fixture.target / ".config/starship.toml").read_text())
    require(
        starship["directory"]["truncation_length"] == 5,
        "prompt directory truncation drift",
    )
    require(starship["cmd_duration"]["disabled"], "prompt duration drift")
    protocol = (fixture.target / ".config/gh/config.yml").read_text()
    require(f"git_protocol: {platform['ghProtocol']}" in protocol, "gh protocol drift")
    require(
        not (fixture.target / ".config/gh/hosts.yml").exists(),
        "gh authentication became managed",
    )
    require(
        not (fixture.target / ".ssh/id_ed25519").exists(),
        "private SSH identity became managed",
    )
    require(not (fixture.target / ".zsh_history").exists(), "history became managed")
    require(not (fixture.target / ".omp").exists(), "OMP state became managed")
    if fixture.target_os == "darwin" and host["roles"]["desktop"]:
        require(
            f"/etc/profiles/per-user/{platform['username']}/bin" in shell,
            "user profile precedence missing",
        )
        tern_index = next(
            index
            for index, app in enumerate(host["applications"])
            if Path(app.get("appPath", "")).name == "Tern.app"
        )
        require(
            host["applications"][tern_index]["appPath"] + "/Contents/MacOS" in shell,
            "declared Tern CLI path missing",
        )
    # Native zsh starts with detached stdin; ordinary tools come from the same
    # derivations installed by the host, not an ad-hoc package set.
    env = fixture.env | {
        "ZDOTDIR": str(fixture.target),
        "PATH": os.environ["userPath"] + ":" + fixture.env["PATH"],
    }
    process = subprocess.run(
        ["zsh", "-l", "-i", "-c", "exit"],
        stdin=subprocess.DEVNULL,
        capture_output=True,
        text=True,
        env=env,
    )
    require(process.returncode == 0, process.stderr)
    require("zle" not in process.stderr.lower(), "detached shell emitted a zle warning")
    if fixture.target_os == "darwin" and host["roles"]["desktop"]:
        # The vendor GUI application is outside a build sandbox. Probe actual
        # shell resolution with a unique executable in a disposable declared
        # bundle; live availability/behavior remains the Tern acceptance gate.
        tern_bundle = fixture.work / "Tern.app"
        command = tern_bundle / "Contents/MacOS/tern"
        command.parent.mkdir(parents=True, exist_ok=True)
        command.write_text("#!/bin/sh\nexit 0\n")
        command.chmod(0o755)
        changed_host = copy.deepcopy(host)
        changed_host["applications"][tern_index]["appPath"] = str(tern_bundle)
        targets = [str(fixture.target / name) for name in (".zshenv", ".zshrc")]
        try:
            fixture.run(
                "apply",
                "--exclude=scripts",
                *targets,
                overrides={"hosts": {fixture.host: changed_host}},
            )
            # The build host's /etc/zprofile is not this repository's: stock
            # macOS runs path_helper there and reorders PATH. nix-darwin's
            # replacement does not, so probe only the rendered user files.
            for flags in (["-l", "-c"], ["-l", "-i", "-c"]):
                resolved = subprocess.run(
                    [
                        "zsh",
                        "-o",
                        "no_global_rcs",
                        *flags,
                        'command -v tern; print -r -- "$path[1]"',
                    ],
                    stdin=subprocess.DEVNULL,
                    capture_output=True,
                    text=True,
                    env=env,
                )
                require(
                    resolved.returncode == 0
                    and resolved.stdout.splitlines()
                    == [str(command), str(fixture.target / ".local/bin")],
                    f"Tern CLI or local-bin precedence lost in zsh {' '.join(flags)}",
                )
        finally:
            fixture.run("apply", "--exclude=scripts", *targets)


def assert_git_worktrees(fixture, facts):
    host = facts["hosts"][fixture.host]
    if not host["roles"].get("wslWorkstation"):
        return
    # The same conditional include is tested after substituting only its
    # declared home prefix, allowing a disposable worktree outside real HOME.
    platform = host["platforms"][fixture.target_os]
    config = fixture.target / ".gitconfig"
    original = config.read_text()
    git_home = fixture.work / "git-home"
    config.write_text(original.replace(platform["home"], str(git_home)))
    try:
        for directory, email in [
            ("src/gitlab.scch.at/work", host["git"]["defaultEmail"]),
            ("src/github.com/any-owner/project", host["git"]["githubNoReplyEmail"]),
            ("other/project", host["git"]["defaultEmail"]),
        ]:
            repo = git_home / directory
            repo.mkdir(parents=True)
            subprocess.run(
                ["git", "init", "-q", str(repo)], env=fixture.env, check=True
            )
            require(
                git_value(fixture, "user.email", repo) == email,
                "conditional Git identity drift",
            )
            subprocess.run(
                [
                    "git",
                    "-C",
                    str(repo),
                    "config",
                    "user.email",
                    "fixture-local@example.invalid",
                ],
                env=fixture.env,
                check=True,
            )
            require(
                git_value(fixture, "user.email", repo)
                == "fixture-local@example.invalid",
                "local Git override lost",
            )
    finally:
        config.write_text(original)


def assert_modify_files(fixture, manifest):
    if "karabiner" not in manifest:
        return
    targets = [
        fixture.target / ".config/zed/settings.json",
        fixture.target / ".config/karabiner/karabiner.json",
    ]
    for path in targets:
        original = path.read_bytes()
        path.write_bytes(b"{malformed fixture")
        fixture.run("apply", "--exclude=scripts", str(path), success=False)
        require(
            path.read_bytes() == b"{malformed fixture",
            "malformed app configuration was overwritten",
        )
        path.unlink()
        fixture.run("apply", "--exclude=scripts", str(path))
        require(
            path.is_file() and not path.is_symlink(),
            "absent app configuration did not initialize",
        )
        path.write_bytes(original)
        fixture.run("apply", "--exclude=scripts", str(path))
    zed = json.loads(targets[0].read_text())
    require(zed["fixture_ui_state"] == {"zoom": 42}, "Zed UI state lost")

    def assert_settings(actual, desired):
        for key, value in desired.items():
            if isinstance(value, dict):
                assert_settings(actual[key], value)
            else:
                require(actual[key] == value, f"shared Zed setting drift: {key}")

    assert_settings(zed, manifest["zed"]["settings"])
    karabiner = json.loads(targets[1].read_text())
    require(
        karabiner["global"]["fixture_ui_state"] == 42, "Karabiner global UI state lost"
    )
    require(
        any(
            profile["name"] == "Unmanaged fixture" for profile in karabiner["profiles"]
        ),
        "Karabiner unrelated profile lost",
    )
    declaration = json.loads(Path(manifest["karabiner"]["declaration"]).read_text())
    require(
        [p["name"] for p in karabiner["profiles"] if p.get("selected")]
        == [p["name"] for p in declaration["profiles"] if p["selected"]],
        "Karabiner managed selection did not deselect unrelated profiles",
    )
    for desired in declaration["profiles"]:
        profile = next(
            profile
            for profile in karabiner["profiles"]
            if profile["name"] == desired["name"]
        )
        rules = profile["complex_modifications"]["rules"]
        descriptions = [rule["description"] for rule in rules]
        require(
            "Fixture unmanaged rule" in descriptions,
            "Karabiner unrelated managed-profile rule lost",
        )
        for rule in desired["complex_modifications"]["rules"]:
            require(
                descriptions.count(rule["description"]) == 1,
                "Karabiner managed rule duplicated",
            )
    require(
        stat.S_IMODE(targets[1].stat().st_mode) == 0o600,
        "Karabiner file is not private",
    )
    require(
        stat.S_IMODE(targets[1].parent.stat().st_mode) == 0o700,
        "Karabiner directory is not private",
    )


def assert_init(fixture):
    config = fixture.work / "init.toml"
    command = [
        "chezmoi",
        "--no-tty",
        "--source",
        str(fixture.source),
        "--destination",
        str(fixture.target),
        "--config",
        str(config),
        "--override-data",
        json.dumps(fixture.overrides),
        "init",
        "--promptString",
        "host=" + fixture.host,
    ]
    initialized = subprocess.run(
        command, env=fixture.env, capture_output=True, text=True
    )
    require(initialized.returncode == 0, f"init failed: {initialized.stderr}")
    configured = tomllib.loads(config.read_text())
    require(
        configured["sourceDir"] == str(fixture.source), "init created a second checkout"
    )
    require(
        configured["data"]["host"] == fixture.host, "init did not persist explicit host"
    )
    if fixture.target_os == "darwin":
        require(
            configured.get("encryption") == "age"
            and configured.get("useBuiltinAge") is True
            and "useBuiltinAge" not in configured["age"],
            "init did not select top-level built-in age",
        )
    initialized = subprocess.run(
        command, env=fixture.env, capture_output=True, text=True
    )
    require(initialized.returncode == 0, f"re-init failed: {initialized.stderr}")
    require(
        tomllib.loads(config.read_text())["sourceDir"] == str(fixture.source),
        "existing local config lost sourceDir",
    )
    for name, destination in [
        ("unknown", fixture.target),
        (fixture.host, fixture.source / "home"),
    ]:
        rejected = [
            "chezmoi",
            "--no-tty",
            "--source",
            str(fixture.source),
            "--destination",
            str(destination),
            "--config",
            str(fixture.work / (name + "-rejected.toml")),
            "--override-data",
            json.dumps(fixture.overrides),
            "init",
            "--promptString",
            "host=" + name,
        ]
        result = subprocess.run(
            rejected, env=fixture.env, capture_output=True, text=True
        )
        require(result.returncode != 0, "invalid host/source-target overlap accepted")


def assert_script_doubles(fixture, facts, manifest):
    scripts = fixture.scripts()
    if not scripts:
        return
    doubles = fixture.work / "doubles"
    doubles.mkdir()
    log = fixture.work / "helper-calls.jsonl"
    fixture.env.update(
        CHEZMOI_HELPER_LOG=str(log), PATH=str(doubles) + ":" + fixture.env["PATH"]
    )
    names = {
        "neo": "neo-keyboard-layout-install",
        "defaultApplications": "default-applications",
        "symbolicHotkeys": "symbolic-hotkeys",
        "appleTerminalFont": "apple-terminal-font",
    }
    names = {
        concern: helper for concern, helper in names.items() if concern in manifest
    }
    commands = set(names.values()) | {"bat"}
    double = (
        "#!"
        + shutil.which("python3")
        + "\n"
        + (
            "import json, os, pathlib, sys\n"
            'with open(os.environ["CHEZMOI_HELPER_LOG"], "a") as f:\n'
            ' f.write(json.dumps([pathlib.Path(sys.argv[0]).name, *sys.argv[1:]]) + "\\n")\n'
            'sys.exit(19 if os.environ.get("CHEZMOI_FAIL_HELPER") == pathlib.Path(sys.argv[0]).name else 0)\n'
        )
    )
    for name in commands:
        path = doubles / name
        path.write_text(double)
        path.chmod(0o755)
    # Only the screenshot path is replaced: mkdir must never touch the real
    # shared host path, even in the script-only fixture.
    script_host = copy.deepcopy(facts["hosts"][fixture.host])
    script_host["paths"]["screenshots"] = str(fixture.work / "screenshots")
    overrides = {"hosts": {fixture.host: script_host}}
    for script in fixture.scripts(overrides).values():
        for line in script.splitlines():
            if not line.strip() or line.startswith("#") or line == "set -eu":
                continue
            command = shlex.split(line)
            require(
                command[0] in commands
                or command == ["mkdir", "-p", script_host["paths"]["screenshots"]],
                "setup fixture contains an undoubled command",
            )
    before_dry_run = snapshot(fixture.target)
    fixture.run("apply", "--include=scripts", "--dry-run", overrides=overrides)
    require(not log.exists(), "dry run executed a helper")
    require(
        snapshot(fixture.target) == before_dry_run, "dry run modified destination state"
    )
    require(
        not Path(script_host["paths"]["screenshots"]).exists(),
        "dry run prepared screenshot directory",
    )
    fixture.run("apply", "--include=scripts", overrides=overrides)
    calls = (
        [json.loads(line) for line in log.read_text().splitlines()]
        if log.exists()
        else []
    )
    require({call[0] for call in calls} == commands, "setup helper ownership drift")
    expected = {"bat": ["cache", "--build"]}
    if names:
        expected.update(
            {
                "neo-keyboard-layout-install": [
                    manifest["neo"]["source"],
                    facts["hosts"][fixture.host]["platforms"][fixture.target_os]["home"]
                    + "/Library/Keyboard Layouts/neo-layouts.bundle",
                ],
                "default-applications": [
                    "--declaration",
                    manifest["defaultApplications"]["declaration"],
                ],
                "symbolic-hotkeys": [
                    str(value) for value in manifest["symbolicHotkeys"]["disabled"]
                ],
                "apple-terminal-font": [manifest["appleTerminalFont"]["font"]],
            }
        )
    for call in calls:
        require(
            call[1:] == expected[call[0]],
            f"{call[0]} arguments differ from resources/destination",
        )
    before = log.read_bytes()
    fixture.run("apply", "--include=scripts", overrides=overrides)
    require(log.read_bytes() == before, "unchanged onchange scripts executed twice")
    scripts = fixture.scripts(overrides)
    if names:
        require(
            Path(script_host["paths"]["screenshots"]).is_dir(),
            "screenshot script did not prepare declared directory",
        )
        changed_screenshots = copy.deepcopy(script_host)
        changed_screenshots["paths"]["screenshots"] = str(
            fixture.work / "updated-screenshots"
        )
        changed_overrides = {"hosts": {fixture.host: changed_screenshots}}
        require(
            fixture.scripts(changed_overrides) != scripts,
            "screenshot path missing from change hash",
        )
        fixture.run("apply", "--include=scripts", overrides=changed_overrides)
        require(
            Path(changed_screenshots["paths"]["screenshots"]).is_dir(),
            "changed screenshot path was not prepared",
        )
        require(
            log.read_bytes() == before, "screenshot path update reran unrelated helpers"
        )
        fixture.run("apply", "--include=scripts", overrides=overrides)
    for relative in (
        "dot_config/bat/config",
        "dot_config/bat/themes/Catppuccin Mocha.tmTheme",
    ):
        asset = fixture.source / "home" / relative
        original_asset = asset.read_bytes()
        asset.write_bytes(original_asset + b"\n")
        changed_scripts = fixture.scripts(overrides)
        changed_names = {
            name for name in scripts if scripts[name] != changed_scripts[name]
        }
        require(
            changed_names == {"run_onchange_after_bat-cache.sh.tmpl"},
            "bat resource update has wrong change hash",
        )
        old_count = len(log.read_text().splitlines())
        fixture.run("apply", "--include=scripts", overrides=overrides)
        calls = [json.loads(line) for line in log.read_text().splitlines()[old_count:]]
        require(
            calls == [["bat", "cache", "--build"]],
            "bat resource update did not rerun only its cache",
        )
        asset.write_bytes(original_asset)
        fixture.run("apply", "--include=scripts", overrides=overrides)
    # Each relevant resource/helper identity update must change its script
    # hash and rerun that concern; testing the real ledger catches a missing
    # run_onchange attribute as well as a missing hash comment.
    manifest_path = fixture.resources / "manifest.json"
    for concern, helper in names.items():
        for field in (
            "helper",
            next(key for key in manifest[concern] if key != "helper"),
        ):
            changed = copy.deepcopy(manifest)
            value = changed[concern][field]
            if isinstance(value, list):
                changed[concern][field] = value + [999]
            else:
                changed[concern][field] = value + "-fixture-update"
            manifest_path.write_text(json.dumps(changed))
            rendered = fixture.scripts(overrides)
            changed_names = {
                name for name in scripts if scripts[name] != rendered[name]
            }
            expected_names = {
                name for name, content in scripts.items() if helper + " " in content
            }
            require(
                changed_names == expected_names and len(changed_names) == 1,
                f"{concern}.{field} has wrong script hash",
            )
            old_count = len(log.read_text().splitlines())
            fixture.run("apply", "--include=scripts", overrides=overrides)
            new_calls = [
                json.loads(line) for line in log.read_text().splitlines()[old_count:]
            ]
            require(
                len(new_calls) == 1 and new_calls[0][0] == helper,
                f"{concern} update did not rerun only its helper",
            )
            manifest_path.write_text(json.dumps(manifest))
            fixture.run("apply", "--include=scripts", overrides=overrides)
    if names:
        changed = copy.deepcopy(manifest)
        changed["neo"]["helper"] += "-failure-fixture"
        manifest_path.write_text(json.dumps(changed))
        failing_helper = "neo-keyboard-layout-install"
    else:
        bat_config = fixture.source / "home/dot_config/bat/config"
        bat_config.write_text(bat_config.read_text() + "\n# failure fixture\n")
        failing_helper = "bat"
    old_count = len(log.read_text().splitlines())
    fixture.env["CHEZMOI_FAIL_HELPER"] = failing_helper
    fixture.run("apply", "--include=scripts", overrides=overrides, success=False)
    failed_calls = [
        json.loads(line) for line in log.read_text().splitlines()[old_count:]
    ]
    require(
        len(failed_calls) == 1 and failed_calls[0][0] == failing_helper,
        "apply failed outside the helper failure fixture",
    )
    fixture.env.pop("CHEZMOI_FAIL_HELPER")
    manifest_path.write_text(json.dumps(manifest))
    if not names:
        bat_config.write_text(
            bat_config.read_text().removesuffix("\n# failure fixture\n")
        )


def main():
    out = Path(os.environ["out"])
    out.mkdir()
    with tempfile.TemporaryDirectory() as temporary:
        work = Path(temporary)
        source = work / "source"
        shutil.copytree(os.environ["source"], source)
        source.chmod(source.stat().st_mode | stat.S_IWUSR)
        for path in source.rglob("*"):
            if not path.is_symlink():
                path.chmod(path.stat().st_mode | stat.S_IWUSR)
        facts = {}
        for path in (source / "home/.chezmoidata").glob("*.toml"):
            facts.update(tomllib.loads(path.read_text()))
        (out / "facts.json").write_text(json.dumps(facts))
        resources = out / "resources"
        resources.mkdir()
        manifest = json.loads(os.environ["resourceManifest"])
        (resources / "manifest.json").write_text(json.dumps(manifest))
        fixture = Fixture(
            source,
            out / "home",
            resources,
            os.environ["hostName"],
            os.environ["targetOS"],
            work,
        )
        # Rendering ignore selection needs no age identity. Check mode must
        # exclude exactly the production-secret subtree and nothing ordinary.
        ignore = (source / "home/.chezmoiignore").read_text()
        checked = fixture.run("execute-template", input=ignore)
        normal = fixture.run(
            "execute-template", input=ignore, overrides={"checkMode": False}
        )

        def lines(text):
            return {
                line.strip()
                for line in text.splitlines()
                if line.strip() and not line.startswith("#")
            }

        require(
            lines(checked) ^ lines(normal)
            <= {".config/credentials/**", ".config/credentials"},
            "checkMode changes ordinary ownership",
        )
        if fixture.target_os == "darwin":
            require(
                ".config/credentials/**" in lines(checked),
                "production ciphertext not excluded in checkMode",
            )
        for excluded_os in ("linux", "windows"):
            overrides = {
                "chezmoi": fixture.overrides["chezmoi"] | {"os": excluded_os},
                "checkMode": False,
                **({"host": "korolev"} if excluded_os == "windows" else {}),
            }
            selected = fixture.run(
                "execute-template", input=ignore, overrides=overrides
            )
            require(
                {".config/credentials", ".config/credentials/**"} <= lines(selected),
                f"{excluded_os} exposes production credentials without checkMode",
            )
            managed = fixture.run("managed", overrides=overrides).splitlines()
            require(
                not any(
                    path == ".config/credentials"
                    or path.startswith(".config/credentials/")
                    for path in managed
                ),
                f"{excluded_os} manages production credential sources",
            )
        assert_init(fixture)
        if "karabiner" in manifest:
            zed = fixture.target / ".config/zed/settings.json"
            zed.parent.mkdir(parents=True)
            zed.write_text(
                "// app-owned JSONC fixture"
                + chr(10)
                + '{"fixture_ui_state":{"zoom":42}}'
            )
            karabiner = fixture.target / ".config/karabiner/karabiner.json"
            karabiner.parent.mkdir(parents=True, mode=0o700)
            declaration = json.loads(
                Path(manifest["karabiner"]["declaration"]).read_text()
            )
            karabiner.write_text(
                json.dumps(
                    {
                        "global": {"fixture_ui_state": 42},
                        "profiles": [
                            {
                                "name": "Unmanaged fixture",
                                "selected": True,
                                "complex_modifications": {"rules": []},
                            },
                            {
                                "name": declaration["profiles"][0]["name"],
                                "complex_modifications": {
                                    "rules": [
                                        {
                                            "description": "Fixture unmanaged rule",
                                            "manipulators": [],
                                        }
                                    ]
                                },
                            },
                        ],
                    }
                )
            )
            karabiner.chmod(0o600)
        retired = [
            line.strip()
            for line in fixture.run(
                "execute-template", input=(source / "home/.chezmoiremove").read_text()
            ).splitlines()
            if line.strip() and not line.lstrip().startswith("#")
        ]
        legacy_source = work / "immutable-legacy-config"
        legacy_source.write_text("retired Home Manager fixture\n")
        legacy_source.chmod(0o444)
        brave_ancestors = []
        host = facts["hosts"][fixture.host]
        if fixture.target_os == "darwin" and host["roles"]["desktop"]:
            parent = fixture.target
            for name in (
                "Library",
                "Application Support",
                "BraveSoftware",
                "Brave-Browser",
                "External Extensions",
            ):
                parent = parent / name
                parent.mkdir(mode=0o700)
                brave_ancestors.append(parent)
        for relative in retired:
            path = fixture.target / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.symlink_to(legacy_source)
        fixture.run("apply", "--exclude=scripts")
        fixture.run("verify", "--exclude=scripts")
        for parent in brave_ancestors:
            require(
                stat.S_IMODE(parent.stat().st_mode) == 0o700,
                f"apply widened private Brave ancestor permissions: {parent.name}",
            )
        require(
            all(
                not (fixture.target / relative).exists()
                and not (fixture.target / relative).is_symlink()
                for relative in retired
            ),
            "retired Home Manager destination survived apply",
        )
        require(
            legacy_source.read_text() == "retired Home Manager fixture\n",
            "retiring a symlink modified its immutable source",
        )
        before = snapshot(fixture.target)
        fixture.run("apply", "--exclude=scripts")
        fixture.run("verify", "--exclude=scripts")
        require(
            snapshot(fixture.target) == before,
            "repeat apply changed content, mode or mtime",
        )
        require(
            not (fixture.target / ".config/credentials").exists(),
            "production secret reached check target",
        )
        assert_portable(fixture, facts)
        assert_git_worktrees(fixture, facts)
        assert_modify_files(fixture, manifest)
        changed_host = copy.deepcopy(facts["hosts"][fixture.host])
        changed_host["git"]["defaultEmail"] = "shared-fixture@example.invalid"
        changed_host["platforms"][fixture.target_os]["ghqRoot"] = str(
            work / "changed-ghq"
        )
        fixture.run(
            "apply",
            "--exclude=scripts",
            overrides={"hosts": {fixture.host: changed_host}},
        )
        require(
            git_value(fixture, "user.email") == changed_host["git"]["defaultEmail"],
            "shared identity edit did not flow to source",
        )
        require(
            git_value(fixture, "ghq.root") == str(work / "changed-ghq"),
            "shared path edit did not flow to source",
        )
        fixture.run("apply", "--exclude=scripts")
        scripts = fixture.scripts()
        (out / "scripts").mkdir()
        for name, content in scripts.items():
            (out / "scripts" / name.removesuffix(".tmpl")).write_text(content)
        # A real tracked-template mutation must fail the effective assertion,
        # even though chezmoi can successfully render/apply/verify that source.
        git_template = source / "home/dot_gitconfig.tmpl"
        original = git_template.read_text()
        git_template.write_text(
            original + "\n[user]\nemail = fixture-regression@example.invalid\n"
        )
        fixture.run("apply", "--exclude=scripts")
        fixture.run("verify", "--exclude=scripts")
        try:
            assert_portable(fixture, facts)
        except AssertionError as error:
            require(
                str(error) == "shared Git email drift",
                "regression failed for an unrelated reason",
            )
        else:
            raise AssertionError(
                "deliberately bad tracked-template fixture was accepted"
            )
        git_template.write_text(original)
        fixture.run("apply", "--exclude=scripts")
        assert_script_doubles(fixture, facts, manifest)
        if fixture.target_os == "darwin":
            no_role = copy.deepcopy(facts["hosts"][fixture.host])
            no_role["roles"] = {key: False for key in no_role["roles"]}
            overrides = {"hosts": {fixture.host: no_role}}
            no_role_work = work / "no-role"
            no_role_work.mkdir()
            no_role_fixture = Fixture(
                source,
                no_role_work / "home",
                resources,
                fixture.host,
                fixture.target_os,
                no_role_work,
            )
            no_role_fixture.run("apply", "--exclude=scripts", overrides=overrides)
            no_role_fixture.run("verify", "--exclude=scripts", overrides=overrides)
            for destination in (
                ".config/colima",
                ".config/karabiner",
                ".config/zed",
                "Air",
                "Library/Application Support/BraveSoftware",
                ".config/ghostty",
            ):
                require(
                    not (no_role_fixture.target / destination).exists(),
                    f"no-role Darwin fixture applied {destination}",
                )
            require(
                not any(
                    "darwin-desktop" in name for name in fixture.scripts(overrides)
                ),
                "no-role Darwin fixture receives optional setup",
            )
            managed = no_role_fixture.run("managed", overrides=overrides).splitlines()
            for path in (
                ".config/colima",
                ".config/karabiner",
                ".config/zed",
                "Air",
                "Library/Application Support/BraveSoftware/Brave-Browser/External Extensions",
                "darwin-desktop-",
            ):
                require(
                    not any(
                        entry == path
                        or entry.startswith(path + "/")
                        or (path == "darwin-desktop-" and entry.startswith(path))
                        for entry in managed
                    ),
                    f"no-role Darwin fixture owns {path}",
                )
        fixture.run("verify", "--exclude=scripts")
        (out / "evidence.json").write_text(
            json.dumps(
                {
                    "host": fixture.host,
                    "os": fixture.target_os,
                    "trackedSource": True,
                    "repeatApply": True,
                    "regressionRejected": True,
                    "productionSecretsExcluded": True,
                    "setupHelpersDoubled": bool(scripts),
                }
            )
        )


if __name__ == "__main__":
    main()
