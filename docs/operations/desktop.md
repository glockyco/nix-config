# Personal desktop

The personal Windows desktop is reached over the tailnet with `ssh desktop`, `ssh desktop-batch` and Windows App. The [README](../../README.md#network) lists the endpoints. The selected account is an administrator. Ask before changing services.

## Keys

Each source has its own key and a labelled line in `C:\ProgramData\ssh\administrators_authorized_keys`: `air`, `pro-enclave`, `pro-yubikey` and `korolev`. Add a key only from the desktop's own session, after checking its fingerprint. To revoke a source, delete its line and confirm that the source gets `Permission denied (publickey)` while the others still connect.

The file must grant access only to `SYSTEM` and `Administrators`. With wider permissions, sshd rejects every key without a useful error. Put `sshd_config` edits in the global section, before the `Match Group administrators` block, because `sshd -t` accepts a misplaced directive silently.

## Sessions

Agents use `ssh desktop-batch '<command>'`. No multiplexer is installed, so nothing survives a dropped connection. Windows App takes over the signed-in console session, which keeps running after disconnecting.

Unattended access needs the desktop's Tailscale key expiry to stay disabled. Check it in PowerShell on the desktop:

```powershell
(tailscale status --json | ConvertFrom-Json).Self | Select-Object DNSName, Online, KeyExpiry
```

`KeyExpiry` must be empty. The desktop is a tagged node, so it cannot receive Taildrop. Use SFTP instead.

## OpenSSH server updates

The desktop runs the standalone [Win32-OpenSSH](https://github.com/PowerShell/Win32-OpenSSH/releases) ZIP from `C:\Program Files\OpenSSH`. Windows Update does not service it, so check for releases by hand. Update it at the console in an Administrator PowerShell, never over SSH:

1. Keep the current ZIP. Back up `C:\ProgramData\ssh` with its ACLs to a local directory that only Administrators and SYSTEM can read.

1. Check the new ZIP's SHA-256 against the GitHub release digest and the Authenticode signatures of its executables and scripts.

1. Run the old package's `uninstall-sshd.ps1` and confirm that both `sshd` and `ssh-agent` are gone. Restart first if Windows reports them as pending deletion.

1. Extract the new package into `C:\Program Files\OpenSSH` and install it:

   ```powershell
   $ErrorActionPreference = 'Stop'
   & 'C:\Program Files\OpenSSH\install-sshd.ps1'
   Get-Service sshd, ssh-agent | Set-Service -StartupType Automatic
   Start-Service sshd, ssh-agent
   ```

1. From the Mac, run `ssh desktop-batch 'exit 23'` and an SFTP round trip, and confirm that the host key did not change.

Never enable the broad `OpenSSH SSH Server (sshd)` firewall rule or install the MSI, which opens TCP 22 to everyone. The existing rules restrict SSH to tailnet addresses. To recover, reinstall the retained ZIP the same way and restore the backed-up configuration.

## OMP

The desktop runs the standalone OMP executable, installed in binary mode and updated with `omp update`:

```powershell
& ([scriptblock]::Create((irm https://omp.sh/install.ps1))) -Binary
omp plugin marketplace add glockyco/omp-agent-setup
omp plugin install --scope user personal@glockyco
```

OMP's shell must be PowerShell or Git Bash, not the WSL `bash.exe`. The desktop has no language servers.
