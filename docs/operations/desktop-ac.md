# Second personal desktop

DESKTOP-ARNTPG5 is a Windows PC that joins the tailnet as `desktop-ac` with `tag:desktop-ac`. The repository declares only its policy membership in [tailnet-peers.nix](../../modules/shared/tailnet-peers.nix). Everything on the machine is set up by hand.

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
