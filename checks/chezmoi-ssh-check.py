"""Check effective SSH options without ever opening a connection."""

import json
from pathlib import Path
import subprocess
import sys
import tempfile


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def main():
    rendered, host_name, endpoint = sys.argv[1:]
    root = Path(rendered)
    facts = json.loads((root / "facts.json").read_text())
    host = facts["hosts"][host_name]
    platform = host["platforms"]["darwin"]
    windows = endpoint in ("desktop", "korolev")
    if windows:
        require(host["roles"]["desktop"], f"{endpoint} endpoint without desktop role")
        destination = facts["ssh"][endpoint]
    else:
        require(
            endpoint == "air" and host["roles"]["airClient"],
            "Air endpoint without Air role",
        )
        destination = facts["air"]
    with tempfile.TemporaryDirectory() as temporary:
        temporary = Path(temporary)
        config = temporary / "ssh-config"
        # OpenSSH expands ~ using passwd, not HOME. Redirect only this
        # declared target prefix to the applied fixture; policy stays intact.
        text = (root / "home/.ssh/config").read_text()
        config.write_text(
            text.replace("~/", str(root / "home") + "/").replace(
                platform["home"] + "/.ssh/", str(root / "home/.ssh") + "/"
            )
        )
        options = {}
        for alias in (endpoint, endpoint + "-batch"):
            output = subprocess.check_output(
                ["ssh", "-G", "-F", str(config), alias], text=True
            )
            options[alias] = dict(line.split(" ", 1) for line in output.splitlines())
            effective = options[alias]
            for key, expected in {
                "hostname": destination["hostName"],
                "user": destination["user"],
                "stdinnull": "no",
            }.items():
                require(effective.get(key) == expected, f"{alias}: {key} != {expected}")
            if windows:
                for key, expected in {
                    "stricthostkeychecking": "true",
                    "passwordauthentication": "no",
                    "kbdinteractiveauthentication": "no",
                    "updatehostkeys": "false",
                    "globalknownhostsfile": "/dev/null",
                }.items():
                    require(
                        effective.get(key) == expected, f"{alias}: {key} != {expected}"
                    )
                pin = root / f"home/.ssh/{endpoint}-known-hosts"
                require(
                    effective.get("userknownhostsfile") == str(pin),
                    f"{alias}: alternate known-host source",
                )
                key = facts["ssh"][endpoint]["publicKey"]
                name = facts["ssh"][endpoint]["hostName"]
                pins = {f"{name},{name}.{facts['ssh']['tailnetDnsDomain']} {key}"}
                require(
                    set(pin.read_text().splitlines()) == pins,
                    f"{alias}: pin contents drift",
                )
                pinned_key = temporary / "pinned-key"
                pinned_key.write_text(
                    subprocess.check_output(
                        ["ssh-keygen", "-F", destination["hostName"], "-f", str(pin)],
                        text=True,
                    )
                )
                fingerprint = subprocess.check_output(
                    ["ssh-keygen", "-lf", str(pinned_key)], text=True
                ).split()[1]
                expected_key = temporary / "expected-key"
                expected_key.write_text(key + "\n")
                expected_fingerprint = subprocess.check_output(
                    ["ssh-keygen", "-lf", str(expected_key)], text=True
                ).split()[1]
                require(
                    fingerprint == expected_fingerprint,
                    f"{alias}: pin fingerprint drift",
                )
                require(
                    fingerprint == facts["ssh"][endpoint]["fingerprint"],
                    f"{endpoint} pin fingerprint drift",
                )
                require(
                    "Secretive" in effective.get("identityagent", ""),
                    f"{endpoint} Secretive agent drift",
                )
                require(
                    effective.get("identitiesonly") == "no",
                    f"{endpoint} excludes Secretive identities",
                )
        interactive = options[endpoint]
        batch = options[endpoint + "-batch"]
        for key, expected in {
            "batchmode": "no",
            "controlmaster": "auto",
            "requesttty": "auto",
            "connecttimeout": "none",
            "controlpersist": "3600",
        }.items():
            require(
                interactive.get(key) == expected, f"{endpoint}: interactive {key} drift"
            )
        for key, expected in {
            "batchmode": "yes",
            "controlmaster": "false",
            "requesttty": "false",
            "connecttimeout": "8",
            "controlpersist": "no",
        }.items():
            require(batch.get(key) == expected, f"{endpoint}: batch {key} drift")
        require("controlpath" not in batch, f"{endpoint}: batch has ControlPath")
        if endpoint == "desktop":
            hardware = subprocess.check_output(
                ["ssh", "-G", "-F", str(config), "github-yubikey"], text=True
            )
            hardware = dict(line.split(" ", 1) for line in hardware.splitlines())
            require(
                hardware["identityagent"] == "none", "YubiKey traffic uses Secretive"
            )
            require(
                hardware["identitiesonly"] == "yes", "YubiKey identity isolation drift"
            )
            require(
                hardware["identityfile"] == str(root / "home/.ssh/id_ed25519_sk"),
                "YubiKey identity drift",
            )


if __name__ == "__main__":
    main()
