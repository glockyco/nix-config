"""Review supported Windows sshd policy and manual cutover safety, not live state."""

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
    for required in [
        r"non-elevated PowerShell as `scch\jglock`",
        "--unattended=true --shields-up=true",
        "Get-NetIPAddress -InterfaceAlias Tailscale -AddressState Preferred",
        "Node/adapter address mismatch",
        "every non-SSH inbound allow and TCP/UDP listener",
        "Get-NetUDPEndpoint",
        "& sc.exe config sshd start= delayed-auto",
        "& sc.exe failure sshd reset= 86400 actions= restart/30000/restart/60000/restart/120000",
        "& sc.exe failureflag sshd 1",
        "prior delayed-start setting, failure actions/reset period and failure-action flag",
    ]:
        if required not in text:
            raise ValueError(f"missing cutover safety instruction: {required}")
    if not (
        text.index("--shields-up=true")
        < text.index("every non-SSH inbound allow and TCP/UDP listener")
        < text.index("& sc.exe failure sshd")
        < text.index("& $tailscale set --shields-up=false")
    ):
        raise ValueError(
            "inbound enablement precedes enrollment/audit/service readiness"
        )
    adapter_block = text.split("$recordedAddresses = @(Get-Content", 1)[1].split(
        "```", 1
    )[0]
    if "$tailscale" in adapter_block:
        raise ValueError("Administrator address query invokes profile-owned LocalAPI")


text = pathlib.Path(sys.argv[1]).read_text()
validate(text)
for before, after in [
    ("PasswordAuthentication no", "PasswordAuthentication yes"),
    ("ListenAddress WINDOWS_TAILNET_IPV4", "ListenAddress 0.0.0.0"),
    (r"AllowUsers scch\jglock", "AllowUsers administrator"),
    ("DisableForwarding yes", "DisableForwarding no"),
    ("Port 22", "Port 22\nKbdInteractiveAuthentication no"),
    ("Subsystem sftp sftp-server.exe", "Subsystem sftp wsl.exe"),
    ("--unattended=true --shields-up=true", "--unattended=true"),
    (r"non-elevated PowerShell as `scch\jglock`", "Administrator PowerShell"),
    ("Get-NetUDPEndpoint", "Write-Output 'no UDP inventory'"),
    ("& sc.exe config sshd start= delayed-auto", "& sc.exe config sshd start= auto"),
    ("restart/30000/restart/60000/restart/120000", "none/0"),
    (
        "prior delayed-start setting, failure actions/reset period and failure-action flag",
        "prior startup state",
    ),
    (
        "$addresses = @(Get-NetIPAddress",
        "$v4 = & $tailscale ip -4\n$addresses = @(Get-NetIPAddress",
    ),
]:
    try:
        validate(text.replace(before, after, 1))
    except ValueError:
        continue
    raise AssertionError(f"fixture accepted {after}")
print("Windows sshd runbook policy/cutover review and rejection fixtures passed")
