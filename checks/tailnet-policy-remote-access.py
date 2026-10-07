"""Review the runbook's complete supported Windows sshd policy, not live state."""

import pathlib
import sys


EXPECTED = {
    "Port": ["22"],
    "ListenAddress": ["WINDOWS_TAILNET_IPV4", "WINDOWS_TAILNET_IPV6"],
    "AllowUsers": [r"scch\jglock"],
    "AuthenticationMethods": ["publickey"],
    "PubkeyAuthentication": ["yes"],
    "PasswordAuthentication": ["no"],
    "AuthorizedKeysFile": [".ssh/authorized_keys"],
    "DisableForwarding": ["yes"],
    "AllowTcpForwarding": ["no"],
    "AllowAgentForwarding": ["no"],
    "Subsystem": ["sftp sftp-server.exe"],
}


def validate(text):
    blocks = text.split("```sshd_config\n")
    if len(blocks) != 2:
        raise ValueError("expected one complete sshd_config fence")
    directives = {}
    for line in blocks[1].split("```", 1)[0].splitlines():
        key, value = line.split(maxsplit=1)
        if key not in EXPECTED:
            raise ValueError(f"unsupported/unapproved directive: {key}")
        directives.setdefault(key, []).append(value)
    if directives != EXPECTED:
        raise ValueError(f"Windows sshd policy differs: {directives}")


text = pathlib.Path(sys.argv[1]).read_text()
validate(text)
for before, after in [
    ("PasswordAuthentication no", "PasswordAuthentication yes"),
    ("ListenAddress WINDOWS_TAILNET_IPV4", "ListenAddress 0.0.0.0"),
    (r"AllowUsers scch\jglock", "AllowUsers administrator"),
    ("DisableForwarding yes", "DisableForwarding no"),
    ("Port 22", "Port 22\nKbdInteractiveAuthentication no"),
    ("Subsystem sftp sftp-server.exe", "Subsystem sftp wsl.exe"),
]:
    try:
        validate(text.replace(before, after, 1))
    except ValueError:
        continue
    raise AssertionError(f"fixture accepted {after}")
print("Windows sshd runbook policy and six rejection fixtures passed")
