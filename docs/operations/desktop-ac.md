# Second personal desktop

DESKTOP-ARNTPG5 is a Windows PC that joins the tailnet as `desktop-ac` with `tag:desktop-ac`. The repository declares its policy membership in [tailnet-peers.nix](../../modules/shared/tailnet-peers.nix) and the Mac's `ssh desktop-ac` and `ssh desktop-ac-batch` endpoints. Everything on the machine is set up by hand. The account `hho_h` is an administrator. Ask before changing its services.

## Enroll

The tag must be in the applied policy before enrollment, or Tailscale reports that the requested tags are invalid or not permitted. Check that the `tailnet-policy` workflow has applied the revision that declares the peer.

Install Tailscale in an Administrator PowerShell:

```powershell
winget install --id Tailscale.Tailscale --scope machine --exact
```

Enroll in the signed-in standard user's PowerShell, because Tailscale's local API rejects the Administrator account:

```powershell
& 'C:\Program Files\Tailscale\tailscale.exe' up --hostname=desktop-ac --advertise-tags=tag:desktop-ac --unattended=true
```

`--unattended=true` keeps the node connected before sign-in.

## Key expiry

Disable the node's key expiry in the Tailscale admin console, or the machine drops off the tailnet when the key expires. Check it on the machine:

```powershell
(tailscale status --json | ConvertFrom-Json).Self | Select-Object DNSName, Online, KeyExpiry
```

`KeyExpiry` must be empty.

## Firewall

Tailscale's `Tailscale-In` rules allow any protocol to the node's tailnet addresses, so every tailnet peer reaches every listening port. Membership grants no Windows account access.

## SSH

The machine runs the in-box OpenSSH Server capability, which Windows Update services. Its default shell is Windows PowerShell 5.1, set in `HKLM:\SOFTWARE\OpenSSH\DefaultShell`.

- The Mac's Secretive key is the only line in `C:\ProgramData\ssh\administrators_authorized_keys`, labelled `pro-enclave`. The file must grant access only to `SYSTEM` and `Administrators`, or sshd rejects every key. Windows here is German, so grant by SID, because `icacls` fails on English group names: `icacls $k /inheritance:r /grant '*S-1-5-32-544:F' /grant '*S-1-5-18:F'`.
- `PasswordAuthentication no` and `KbdInteractiveAuthentication no` sit in the global section of `sshd_config`, before `Match Group administrators`. Check with `sshd -T` after an edit.
- The capability's `OpenSSH-Server-In-TCP` firewall rule stays disabled. It opens TCP 22 on every network. `Tailscale-In` admits tailnet peers, so SSH answers on the tailnet and not on the LAN.

The Mac pins the host key in [ssh.toml](../../home/.chezmoidata/ssh.toml). If the key changes, verify the new one at the machine before updating the pin.

## Tern

Tern on Windows cannot host remote sessions: `tern remote serve` and `tern remote host-key` only print usage. Its web client works instead. The web client needs WebGPU, which browsers allow only on HTTPS or localhost, so tunnel it to the Mac's localhost:

```sh
ssh -L 127.0.0.1:8377:127.0.0.1:8377 desktop-ac-batch 'tern web serve --listen 127.0.0.1:8377'
```

Open the URL it prints, with `127.0.0.1` kept, in a browser on the Mac. The session lasts as long as the SSH command.
