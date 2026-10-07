"""Validate rendered profile and both setup owners without a daemon."""

import json
import os
from pathlib import Path
import re

import yaml


def main():
    root = Path(os.environ["rendered"])
    expected = json.loads(os.environ["profileFacts"])
    profile = yaml.safe_load(
        (root / "home/.config/colima/default/colima.yaml").read_text()
    )
    manifest = json.loads((root / "resources/manifest.json").read_text())
    assert manifest["colima"]["arch"] == os.environ["expectedArch"]
    for key, value in {
        "arch": os.environ["expectedArch"],
        "autoActivate": True,
        "cpu": expected["cpu"],
        "disk": expected["disk"],
        "memory": expected["memory"],
        "forwardAgent": False,
        "mountType": "virtiofs",
        "rosetta": True,
        "runtime": "docker",
        "vmType": "vz",
        "mounts": expected["mounts"],
    }.items():
        assert profile[key] == value, f"Colima {key} drift"
    assert all(profile[key] > 0 for key in ("cpu", "disk", "memory"))
    assert profile["mounts"]
    assert profile["network"] == {
        "address": False,
        "hostAddresses": False,
        "mode": "shared",
    }
    assert profile["kubernetes"]["enabled"] is False
    env = (root / "home/.zshenv").read_text()
    assert re.search(r"\bCOLIMA_SAVE_CONFIG=[\"\']?false[\"\']?(?:\s|$)", env), (
        "Colima save config drift"
    )
    assert re.search(r"\bDOCKER_CONTEXT=[\"\']?colima[\"\']?(?:\s|$)", env), (
        "Docker context drift"
    )
    scripts = [Path(os.environ["systemScripts"]).read_text()]
    scripts.extend(path.read_text() for path in (root / "scripts").iterdir())
    for script in scripts:
        assert not re.search(
            r"\bcolima(?:[\"\']|\\\")?\s+(?:start|stop|delete|restart)\b", script
        ), "setup changes Colima lifecycle"
        assert "/var/run/docker.sock" not in script, "setup owns global Docker socket"


if __name__ == "__main__":
    main()
