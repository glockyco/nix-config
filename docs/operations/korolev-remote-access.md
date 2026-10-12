# Korolev remote access

The Mac reaches Korolev with `ssh korolev` and `ssh korolev-batch`. Both open PowerShell 7 as `scch\jglock`. [windows/apply-openssh.ps1](../../windows/apply-openssh.ps1) owns the server: the OpenSSH capability, the default shell, the authorized keys, `sshd_config`, the firewall rule and the service. sshd listens only on Korolev's tailnet addresses and accepts only the keys listed in that script.

## Prerequisites

Korolev must be on the office network or connected to the FortiClient VPN. `scch\jglock` is a domain account, and Windows needs a domain controller to log it on with a key. Without one, sshd closes each connection right after authentication.

Tailscale for Windows must be enrolled as `korolev` with tag `tag:korolev`. Enroll it in the standard user's PowerShell, because Tailscale's local API belongs to the signed-in user and rejects the Administrator account:

```powershell
& 'C:\Program Files\Tailscale\tailscale.exe' up --hostname=korolev --advertise-tags=tag:korolev --unattended=true
```

## Set up or repair

Run the script at the console in an Administrator PowerShell 7. A repair restarts sshd and ends open SSH sessions.

```powershell
pwsh -NoProfile -File <checkout>\windows\apply-openssh.ps1 -Test
pwsh -NoProfile -File <checkout>\windows\apply-openssh.ps1
```

`-Test` names every difference and changes nothing. A run converges all of them and is safe to repeat. It changes nothing if Korolev has no tailnet address or `scch\jglock` is a local administrator. It leaves sshd stopped if another enabled inbound firewall rule could admit TCP 22. If Windows reports that the capability finishes installing at the next restart, restart and run the script again.

On the first run the script creates the host keys and prints the fingerprint. Compare it at the console with `ssh.korolev.fingerprint` in [ssh.toml](../../home/.chezmoidata/ssh.toml). If the host keys are ever recreated, replace `publicKey` and `fingerprint` there.

Run the script again after Korolev's tailnet addresses change, for example after enrolling again, because sshd and the firewall rule name the addresses.

## Keys

The script's `$authorizedKeys` holds one labelled public key per source. To add or revoke a source, change that list, merge it and run the script. Never copy a private key to another machine.

## Sessions

Agents use `ssh korolev-batch '<command>'`. It runs without a terminal, preserves stdin and returns the remote exit status. `sftp korolev-batch` transfers files.

Terminal sessions are for people. Win32-OpenSSH always reports exit status 0 for them ([#1737](https://github.com/PowerShell/Win32-OpenSSH/issues/1737)) and strips double quotes from a command passed with `ssh -t`. A terminal session also ends as soon as its stdin closes.

The Mac's entries silence the client's post-quantum warning, because the in-box Windows OpenSSH has no post-quantum key exchange ([#2433](https://github.com/PowerShell/Win32-OpenSSH/issues/2433)).

Port and agent forwarding are disabled. Nothing survives a dropped connection, and Korolev is unreachable while it sleeps.

## Network boundary

No other interface reaches sshd. It binds only the tailnet addresses, and its firewall rule admits only tailnet sources. Never enable the capability's own `OpenSSH-Server-In-TCP` rule, which admits every network.

Tailscale's shields-up is off, so tailnet peers also reach Korolev's other listening ports. The [tailnet policy](../../lib/tailnet-policy.nix) decides which peers may connect.

To turn SSH off, run in an Administrator PowerShell:

```powershell
Stop-Service sshd
Set-Service sshd -StartupType Disabled
Remove-NetFirewallRule -Name Korolev-OpenSSH-Tailnet-In-TCP
```
