#!/usr/bin/env python3
"""Exercise source selection with real Git repositories and isolated build phases."""

import importlib.util
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import tempfile
import unittest


SOURCE = Path(sys.argv.pop(1)).resolve()
PROFILE = Path(sys.argv.pop(1)).resolve()
spec = importlib.util.spec_from_file_location("omp_dev_update", SOURCE)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class SourceUpdateTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name)
        self.home = self.directory / "home"
        self.home.mkdir()
        self.upstream = self.directory / "upstream"
        self.patch = self.directory / "patch"
        self.git_bin = shutil.which("git")
        self.git_env = os.environ | {
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_CONFIG_GLOBAL": os.devnull,
            "GIT_AUTHOR_NAME": "Updater test",
            "GIT_AUTHOR_EMAIL": "test@localhost",
            "GIT_COMMITTER_NAME": "Updater test",
            "GIT_COMMITTER_EMAIL": "test@localhost",
        }
        self.git("init", self.upstream)
        scripts = self.upstream / "packages/coding-agent/scripts"
        scripts.mkdir(parents=True)
        launcher = scripts / "omp"
        launcher.write_text('#!/bin/sh\nprintf "%s\\n" "$PWD" "$@"\n', encoding="utf-8")
        launcher.chmod(0o755)
        (self.upstream / "feature").write_text("base\n", encoding="utf-8")
        self.base = self.commit(self.upstream, "base")
        self.git("-C", self.upstream, "tag", "v1.0.0")
        self.git("clone", self.upstream, self.patch)
        (self.patch / "feature").write_text("patched\n", encoding="utf-8")
        self.tip = self.commit(self.patch, "personal fix")
        self.tools = self.directory / "tools"
        (self.tools / "bin").mkdir(parents=True)
        self.nix = self.tools / "bin/nix"
        self.nix.write_text(
            '#!/bin/sh\nwhile [ "$1" != --command ]; do shift; done\nshift\nexec "$@"\n',
            encoding="utf-8",
        )
        self.nix.chmod(0o755)
        self.config = {
            "upstreamUrl": str(self.upstream),
            "githubRepo": "test/omp",
            "patchUrl": str(self.patch),
            "patchBase": self.base,
            "patchTip": self.tip,
            "system": "x86_64-linux",
            "plugin": str(self.directory / "plugin"),
            "git": self.git_bin,
            "gh": "/bin/false",
            "nix": str(self.nix),
            "nixStore": "/bin/false",
            "nixPackage": str(PROFILE),
        }
        self.release = ("v1.0.0", self.base)
        self.prepared = []
        self.failure = None
        self.updater = self.make_updater()
        self.protected = self.home / ".omp/agent/settings.yml"
        self.protected.parent.mkdir(parents=True)
        self.protected.write_text("protected runtime state\n", encoding="utf-8")

    def git(self, *args):
        result = subprocess.run(
            [self.git_bin, "-c", "commit.gpgSign=false", *map(str, args)],
            env=self.git_env,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        return result.stdout.strip()

    def commit(self, directory, message):
        self.git("-C", directory, "add", ".")
        self.git("-C", directory, "commit", "-m", message)
        return self.git("-C", directory, "rev-parse", "HEAD")

    def make_updater(self, **kwargs):
        return module.Updater(
            self.config,
            self.home,
            release_provider=lambda: self.release,
            prepare_phase=self.prepare,
            **kwargs,
        )

    def prepare(self, phase, candidate, env):
        self.prepared.append((phase, candidate))
        self.assertEqual(env["HOME"], str(candidate / ".verification-home"))
        self.assertTrue(Path(env["PI_CODING_AGENT_DIR"]).is_relative_to(candidate))
        if phase == self.failure:
            raise module.UpdateError(f"Rejected {phase}")
        if phase == "environment":
            (candidate / "dev-profile").symlink_to(PROFILE)
            (candidate / "nix").symlink_to(self.tools, target_is_directory=True)

    def release_next(self, conflict=False):
        name = "feature" if conflict else "upstream-addition"
        (self.upstream / name).write_text("next release\n", encoding="utf-8")
        commit = self.commit(self.upstream, "next release")
        self.git("-C", self.upstream, "tag", "-a", "v1.1.0", "-m", "Stable release")
        self.release = ("v1.1.0", commit)

    def selected(self, name="current"):
        return (self.updater.root / name).resolve(strict=True)

    def assert_protected(self):
        self.assertEqual(
            self.protected.read_text(encoding="utf-8"), "protected runtime state\n"
        )
        self.assertEqual(list((self.home / ".omp/agent").iterdir()), [self.protected])
        self.assertFalse((self.home / ".bun").exists())

    def test_first_install_replays_patch_and_records_exact_inputs(self):
        metadata = self.updater.update()
        generation = self.selected()
        self.assertEqual(
            (generation / "checkout/feature").read_text(encoding="utf-8"), "patched\n"
        )
        self.assertEqual(metadata["upstream"], self.base)
        self.assertEqual(metadata["patchTip"], self.tip)
        self.assertEqual(
            metadata["commit"],
            self.git("-C", generation / "checkout", "rev-parse", "HEAD"),
        )
        self.assertEqual(self.updater.status(), metadata)
        self.assertFalse((self.updater.root / "previous").exists())
        self.assert_protected()

    def test_unchanged_update_does_not_prepare_another_generation(self):
        metadata = self.updater.update()
        generation = self.selected()
        self.prepared.clear()
        self.assertEqual(self.updater.update(), metadata)
        self.assertEqual(self.selected(), generation)
        self.assertEqual(self.prepared, [])
        self.assertEqual(list(self.updater.generations.iterdir()), [generation])

    def test_promotion_retains_running_generations_and_offline_rollback(self):
        first_metadata = self.updater.update()
        first = self.selected()
        self.release_next()
        second_metadata = self.updater.update()
        second = self.selected()
        self.assertEqual(self.selected("previous"), first)
        self.assertNotEqual(first, second)
        self.assertEqual(
            (second / "checkout/upstream-addition").read_text(encoding="utf-8"),
            "next release\n",
        )
        self.assertEqual(
            (second / "checkout/feature").read_text(encoding="utf-8"), "patched\n"
        )
        shutil.rmtree(self.upstream)
        shutil.rmtree(self.patch)
        self.updater.release_provider = lambda: self.fail(
            "Rollback requested network metadata"
        )
        self.assertEqual(self.updater.rollback(), first_metadata)
        self.assertEqual(self.selected(), first)
        self.assertEqual(self.selected("previous"), second)
        self.assertEqual(self.updater.rollback(), second_metadata)
        self.assertTrue((first / "checkout/feature").is_file())
        self.assert_protected()

    def test_rollback_without_previous_preserves_current(self):
        with self.assertRaisesRegex(module.UpdateError, "No previous"):
            self.updater.rollback()
        self.updater.update()
        selected = self.selected()
        with self.assertRaisesRegex(module.UpdateError, "No previous"):
            self.updater.rollback()
        self.assertEqual(self.selected(), selected)

    def test_each_preparation_failure_preserves_both_selections(self):
        self.updater.update()
        self.release_next()
        self.updater.update()
        current, previous = self.selected(), self.selected("previous")
        (self.patch / "another-fix").write_text("fix\n", encoding="utf-8")
        self.config["patchTip"] = self.commit(self.patch, "another fix")
        for phase in module.PHASES:
            with self.subTest(phase=phase):
                self.failure = phase
                with self.assertRaisesRegex(module.UpdateError, f"Rejected {phase}"):
                    self.updater.update()
                self.assertEqual(self.selected(), current)
                self.assertEqual(self.selected("previous"), previous)
                self.assertFalse((self.updater.candidate / "generation.json").exists())
                self.assert_protected()
        self.failure = None
        self.updater.update()
        self.assertNotEqual(self.selected(), current)
        self.assertEqual(self.selected("previous"), current)
        self.assertTrue(previous.is_dir())

    def test_missing_required_regression_preserves_selection(self):
        self.updater.update()
        current = self.selected()
        self.release_next()

        def prepare_with_missing_regression(phase, candidate, env):
            if phase == "patch-regressions":
                module.Updater.prepare(self.updater, phase, candidate, env)
            else:
                self.prepare(phase, candidate, env)

        self.updater.prepare_phase = prepare_with_missing_regression
        with self.assertRaisesRegex(module.UpdateError, "Patch regression is absent"):
            self.updater.update()
        self.assertEqual(self.selected(), current)
        self.assertFalse((self.updater.candidate / "generation.json").exists())

    def test_patch_conflict_preserves_active_generation_and_candidate(self):
        self.updater.update()
        current = self.selected()
        self.release_next(conflict=True)
        with self.assertRaises(module.UpdateError):
            self.updater.update()
        self.assertEqual(self.updater.phase, "patch-replay")
        self.assertEqual(self.selected(), current)
        self.assertTrue((self.updater.candidate / "checkout/feature").is_file())
        self.assert_protected()

    def test_mismatched_release_commit_and_missing_remote_preserve_selection(self):
        self.updater.update()
        current = self.selected()
        self.release = ("v1.0.0", self.tip)
        with self.assertRaisesRegex(module.UpdateError, "does not match"):
            self.updater.update()
        self.assertEqual(self.selected(), current)
        self.release = ("v1.0.0", self.base)
        (self.patch / "new-fix").write_text("uncached fix\n", encoding="utf-8")
        self.config["patchTip"] = self.commit(self.patch, "uncached fix")
        self.config["patchUrl"] = str(self.directory / "missing")
        with self.assertRaises(module.UpdateError):
            self.updater.update()
        self.assertEqual(self.selected(), current)

    def test_unrelated_patch_base_is_rejected(self):
        self.git("-C", self.patch, "checkout", "--orphan", "unrelated")
        (self.patch / "unrelated").write_text("unrelated\n", encoding="utf-8")
        self.config["patchBase"] = self.commit(self.patch, "unrelated base")
        with self.assertRaises(module.UpdateError):
            self.updater.update()
        self.assertFalse((self.updater.root / "current").exists())
        self.assertIsNone(self.updater.candidate)

    def test_release_metadata_rejects_drafts_prereleases_and_path_tags(self):
        responses = [
            {"draft": True, "prerelease": False, "tag_name": "v1.0.0"},
            {"draft": False, "prerelease": True, "tag_name": "v1.1.0-beta.1"},
            {"draft": False, "prerelease": False, "tag_name": "../../current"},
            {"draft": False, "prerelease": False, "tag_name": "--upload-pack=command"},
            {"draft": False, "tag_name": "v1.0.0"},
        ]
        for response in responses:
            with self.subTest(response=response):
                self.updater.api = lambda _endpoint: response
                with self.assertRaises(module.UpdateError):
                    self.updater.latest_release()
        self.updater.api = lambda endpoint: (
            {"draft": False, "prerelease": False, "tag_name": "v1.0.0"}
            if endpoint == "releases/latest"
            else {"sha": self.base}
        )
        self.assertEqual(self.updater.latest_release(), ("v1.0.0", self.base))

    def test_status_rejects_corrupt_metadata_and_escaped_selection(self):
        self.updater.update()
        generation = self.selected()
        metadata_file = generation / "generation.json"
        metadata = json.loads(metadata_file.read_text(encoding="utf-8"))
        metadata["patchTip"] = "not-a-commit"
        metadata_file.write_text(json.dumps(metadata), encoding="utf-8")
        with self.assertRaises(module.UpdateError):
            self.updater.status()
        current = self.updater.root / "current"
        current.unlink()
        current.symlink_to(self.home)
        with self.assertRaises(module.UpdateError):
            self.updater.status()

    def test_rollback_rejects_missing_profile_and_checkout_identity_change(self):
        self.updater.update()
        first = self.selected()
        self.release_next()
        self.updater.update()
        current = self.selected()
        (first / "dev-profile").unlink()
        with self.assertRaisesRegex(module.UpdateError, "profile"):
            self.updater.rollback()
        self.assertEqual(self.selected(), current)
        (first / "dev-profile").symlink_to(PROFILE)
        self.git("-C", first / "checkout", "checkout", "--detach", self.base)
        with self.assertRaisesRegex(module.UpdateError, "metadata"):
            self.updater.rollback()
        self.assertEqual(self.selected(), current)

    def test_launcher_preserves_working_directory_and_arguments(self):
        self.updater.update()
        caller = self.directory / "unrelated project"
        caller.mkdir()
        arguments = ["acp", "a b", "", "update", "--extension", "literal"]
        output = subprocess.check_output(
            [self.selected() / "omp", *arguments], cwd=caller, text=True
        )
        self.assertEqual(output.splitlines(), [str(caller), *arguments])
        self.assert_protected()

    def test_interrupted_promotion_recovers_previous_before_next_operation(self):
        self.updater.update()
        first = self.selected()
        self.release_next()
        self.updater.update()
        second = self.selected()
        journal = {
            "current": str(second.relative_to(self.updater.root)),
            "previous": str(first.relative_to(self.updater.root)),
            "next": str(first.relative_to(self.updater.root)),
        }
        self.updater.atomic_json(self.updater.root / "promotion.json", journal)
        self.updater.replace_link("previous", journal["current"])
        self.assertEqual(self.updater.rollback()["release"], "v1.0.0")
        self.assertEqual(self.selected(), first)
        self.assertEqual(self.selected("previous"), second)

    def test_promotion_io_failure_restores_both_selections(self):
        self.updater.update()
        first = self.selected()
        self.release_next()
        self.updater.update()
        second = self.selected()
        replace = self.updater.replace_link
        failed = False

        def reject_current(name, target):
            nonlocal failed
            if name == "current" and not failed:
                failed = True
                raise OSError("Selection write failed")
            replace(name, target)

        self.updater.replace_link = reject_current
        with self.assertRaisesRegex(OSError, "Selection write failed"):
            self.updater.rollback()
        self.assertEqual(self.selected(), second)
        self.assertEqual(self.selected("previous"), first)
        self.updater.replace_link = replace
        self.updater.rollback()
        self.assertEqual(self.selected(), first)

    def test_process_lock_blocks_updates_and_releases_after_interruption(self):
        self.updater.update()
        current = self.selected()
        self.release_next()
        config_path = self.directory / "config.json"
        config_path.write_text(json.dumps(self.config), encoding="utf-8")
        child = subprocess.Popen(
            [
                sys.executable,
                "-c",
                """
import importlib.util, json, signal, sys
from pathlib import Path
spec = importlib.util.spec_from_file_location('updater', sys.argv[1])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
config = json.loads(Path(sys.argv[2]).read_text())
def prepare(phase, candidate, env):
    if phase == 'environment':
        (candidate / 'dev-profile').symlink_to(sys.argv[5])
        (candidate / 'nix').symlink_to(sys.argv[6])
    if phase == 'dependencies':
        print('candidate ready', flush=True)
        signal.pause()
signal.signal(signal.SIGTERM, module.interrupted)
class QuietUpdater(module.Updater):
    def run(self, args, **kwargs):
        kwargs['capture'] = True
        return super().run(args, **kwargs)
updater = QuietUpdater(config, sys.argv[3], release_provider=lambda: tuple(json.loads(sys.argv[4])), prepare_phase=prepare)
try:
    updater.update()
except InterruptedError:
    sys.exit(88)
""",
                str(SOURCE),
                str(config_path),
                str(self.home),
                json.dumps(self.release),
                str(PROFILE),
                str(self.tools),
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
        )
        self.addCleanup(lambda: child.poll() is None and child.kill())
        self.assertEqual(child.stdout.readline().strip(), "candidate ready")
        with self.assertRaisesRegex(module.UpdateError, "lock"):
            self.updater.update()
        with self.assertRaisesRegex(module.UpdateError, "lock"):
            self.updater.rollback()
        self.assertEqual(self.selected(), current)
        child.send_signal(signal.SIGTERM)
        self.assertEqual(child.wait(timeout=10), 88)
        child.stdout.close()
        self.assertEqual(self.selected(), current)
        self.updater.update()
        self.assertNotEqual(self.selected(), current)
        self.assertEqual(self.selected("previous"), current)
        self.assert_protected()


if __name__ == "__main__":
    unittest.main()
