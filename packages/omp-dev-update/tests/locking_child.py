"""Hold the update lock until the parent signals interruption."""

import json
from pathlib import Path
import signal
import sys

import omp_dev_update as module


config = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))


def prepare(phase, candidate, env):
    if phase == "environment":
        (candidate / "dev-profile").symlink_to(sys.argv[4])
        (candidate / "nix").symlink_to(sys.argv[5])
    if phase == "dependencies":
        print("candidate ready", flush=True)
        signal.pause()


class QuietUpdater(module.Updater):
    def run(self, args, **kwargs):
        kwargs["capture"] = True
        return super().run(args, **kwargs)


signal.signal(signal.SIGTERM, module.interrupted)
updater = QuietUpdater(
    config,
    sys.argv[2],
    release_provider=lambda: tuple(json.loads(sys.argv[3])),
    prepare_phase=prepare,
)
try:
    updater.update()
except InterruptedError:
    sys.exit(88)
