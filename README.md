# nix-config

Personal workstation configuration for an Apple Silicon MacBook Pro and NixOS under WSL 2. The flake also renders a separately applied Windows configuration and manages [DNS](dns/dnsconfig.js).

## System overview

| Host          | Platform         | Configuration                               |
| ------------- | ---------------- | ------------------------------------------- |
| `macbook-pro` | `aarch64-darwin` | [nix-darwin](hosts/macbook-pro/default.nix) |
| `korolev`     | `x86_64-linux`   | [NixOS/WSL](hosts/korolev/default.nix)      |

Host facts live in [typed declarations](modules/fleet/host.nix) under `hosts/<name>/host.nix`. Each `hosts/<name>/default.nix` selects its roles: the Mac selects [desktop](modules/roles/darwin/desktop/default.nix), [PostgreSQL](modules/roles/darwin/postgresql/default.nix), [container client](modules/roles/darwin/container-client/default.nix), and the temporary [Air client](modules/roles/darwin/air-client/default.nix); Korolev selects [WSL workstation](modules/roles/nixos/wsl-workstation/default.nix). The Darwin and NixOS baselines do not enable these functions on their own. Change a machine value in its host declaration and role policy in its role module.

Nix owns the host configuration and the ordinary tools, including the language servers, OpenSpec, and Plannotator. It does not own OMP: each host installs upstream OMP with the official installer and the personal plugin with OMP's plugin manager (see [OMP](#omp)). OMP owns its writable authentication, configuration, sessions, plugin cache, and databases; activation and Nix rollback do not replace them. Project repositories own their development environments.

## Network

Tailscale connects the MacBook Pro, Korolev, the personal Windows desktop, and the temporary MacBook Air. The MacBook Pro, the desktop, and the Air can initiate connections to one another. Korolev can initiate connections to the other three but does not accept inbound connections.

### Desktop SSH and file access

After Mac activation, `ssh desktop` opens the Windows account's PowerShell session. Use `ssh desktop-batch 'exit 23'` for unattended commands and `sftp desktop-batch` for transfers. The batch endpoint preserves stdin, disables terminal allocation and connection persistence, and uses an eight-second connection timeout.

Both desktop endpoints require the declared host-key pin and reject password fallback. The selected Windows account has administrator privileges; privileged service changes still require explicit owner approval. Windows absolute SFTP paths use `/D:/Projects/ynab`, not `D:/Projects/ynab`. Keep working copies on local storage and preserve originals during transfers.

Graphical access uses Windows App from this Mac against `desktop.tail8768af.ts.net`. The desktop allows one session per user and boots into a signed-in session, so a connection takes over that session rather than opening a private one, and disconnecting retains its work. The Air and Korolev have no RDP client by design; they use SSH and SFTP.

The desktop access change records [acceptance evidence](openspec/changes/archive/2026-09-06-enable-native-windows-remote-work/evidence.md) and [completed deployment gates](openspec/changes/archive/2026-09-06-enable-native-windows-remote-work/tasks.md). The verified standalone Windows OpenSSH server supports hybrid post-quantum key exchange. Its [manual update and recovery procedure](docs/operations/dependency-updates.md#desktop-openssh-maintenance) preserves host keys and tailnet restrictions; client cryptography warnings remain enabled.

### Mac SSH from Korolev

After activating both hosts, `ssh macbook-pro` from Korolev's user opens a shell on the Mac with that user's own key. The session has a terminal, so `darwin-switch` can prompt for the Mac password; run it without `sudo`, because it calls `sudo` itself and a root evaluation cannot read the user-owned checkout. Use `ssh macbook-pro-batch 'exit 23'` for unattended commands; it has the same transport settings as `desktop-batch`. Root and the Nix daemon resolve the same name to the root-only builder key, which cannot open a terminal. The Mac's tailnet daemon refuses forwarding and tunnels for both keys. To revoke the user key alone, remove its line in [the Mac's SSH declaration](modules/roles/darwin/desktop/tailscale.nix) and activate the Mac.

### SCCH share on Korolev

Korolev mounts the SCCH share `\\scch.at\SCCH`, which Windows maps as `S:`, read-only at `/mnt/s`; a path below `S:\` appears at the same relative path below `/mnt/s`. The first access mounts the share through WSL's Windows file bridge with the signed-in Windows session's credentials, so the configuration holds none. Files belong to Korolev's user, and Linux writes fail; change the share from Windows. Boot and activation never wait for the share. While it is unreachable, for example off the corporate network or VPN, every access fails with an error, after up to about 22 seconds, instead of showing an empty directory; the first access after reconnecting mounts it.

## Develop

With Nix and flakes installed, enter the pinned environment. It installs the commit hook; `direnv allow` uses the same shell.

```sh
nix develop
```

Run release gates in order from the repository root, using each host's installed Nix. Finish each Nix command before starting the next; concurrent evaluations of this flake can contend on the shared SQLite evaluation cache.

```sh
nix fmt -- --fail-on-change
nix flake check --print-build-logs
```

Run these additional gates on the Mac:

```sh
nix run .#check-darwin-build-plans
nix build .#darwinConfigurations.macbook-pro.system
```

The build-plan guard needs Darwin store access outside a check sandbox. It rejects uncached source-built toolchains and language servers. [CI](.github/workflows/check.yml) checks both platforms; a local flake check checks only its own system. With the Mac connected to the tailnet, Korolev can build both systems:

```sh
nix flake check --all-systems --print-build-logs
```

Permanent behavior changes use [OpenSpec](openspec/). [Agent guidance](AGENTS.md) explains the repository workflow.

The flake also builds the separately applied [Windows configuration](packages/windows-configuration/package.nix).
Its [packaged check](packages/windows-configuration-check/package.nix) validates the declaration, shipped WinGet document, and PowerShell syntax during `nix flake check`.
This check does not apply Windows resources or prove Windows PowerShell 5.1 behavior.
Follow the [Windows apply procedure](docs/operations/wsl-omp-bootstrap.md#apply-the-windows-layer) for live tests and manual application.

## Activate

Review and merge first. Keep the previous generation and read activation output. For Mac networking changes, retain a local administrator terminal for recovery.

On the Mac, keep this clone at `~/.config/nix-darwin`. First activation:

```sh
sudo nix run .#darwin-rebuild -- switch --flake .#macbook-pro
```

Later activations use `darwin-switch`, which also prints the closure diff. On Korolev, activate from the committed repository:

```sh
sudo nixos-rebuild switch --flake .#korolev
```

An agent can run these activation commands itself in a pseudo-terminal. When `sudo` prompts, the owner types the password into that terminal; agents never ask for or enter it. From Korolev, the agent activates the Mac with `ssh -t macbook-pro 'cd ~/.config/nix-darwin && darwin-switch'`.

Mac activation runs packaged commands for layouts, application handlers, shortcuts, Terminal fonts, power settings, and Rosetta. Each command compares current state before it writes. It reports `current` or names the change. A repeated switch should not rewrite files, re-register applications, import preferences, or reset power settings. An unexpected command error stops activation; inspect the diagnostic before retrying. Quit Terminal.app before verifying its font because it can save old preferences on exit. PostgreSQL keeps its cluster at `/var/lib/postgresql/17`. Activation prepares that directory without moving data.

Before accepting a changed Mac generation, compare the layout, Karabiner, and `FileTypes.app` mtimes across two switches of one revision. Run the built Home Manager activation with `DRY_RUN=1`. Confirm that none of those paths change. Check both power sources and the Rosetta execution probe before and after activation. These live checks require owner authorization; package command tests do not replace them.

After OMP or plugin behavior changes, also complete the [release smoke](docs/operations/dependency-updates.md#release-smoke).

In a fresh local OMP session, use `/plannotator-annotate <path>` to annotate a document or `/plannotator-last` to annotate the last response. Submitted annotations return as feedback, without editing the source or approving implementation. Use `/plannotator-cancel` if a closed browser tab leaves a review pending.

For a new Windows machine, follow [WSL and Windows provisioning](docs/operations/wsl-omp-bootstrap.md). It covers image import, credentials, the separate Windows apply, and recovery. Run one WSL distribution at a time; confirm `systemctl is-active user@1000.service` reports `active` before activation.

For local containers on the Mac, use the [container lifecycle and recovery procedure](docs/operations/container-runtime.md). Activation does not start or delete the VM.

## OMP

Each host runs upstream OMP from the official installer in binary mode, installed to `~/.local/bin`, which the shell puts on `PATH`. Tern is the terminal for interactive sessions. Install OMP, then the personal plugin from the [`glockyco` marketplace](https://github.com/glockyco/omp-agent-setup):

```sh
curl -fsSL https://omp.sh/install | sh -s -- --binary
omp plugin marketplace add glockyco/omp-agent-setup
omp plugin install --scope user personal@glockyco
```

Start a new OMP session afterwards. The plugin supplies the personal policy, skills, `personal_commit`, the Plannotator commands, the language-server overrides, and the OpenSpec workflow as `/personal:opsx-apply`, `/personal:opsx-archive`, `/personal:opsx-explore`, `/personal:opsx-propose`, `/personal:opsx-sync`, and `/personal:opsx-update`.

Update OMP and the plugin independently, then start a new session:

```sh
omp update
omp plugin marketplace update glockyco
omp plugin upgrade --scope user personal@glockyco
```

Check the result with `omp --version` and `omp plugin list`. To return to a known release of OMP, reinstall it with `curl -fsSL https://omp.sh/install | sh -s -- --binary --ref <tag>`; a bad plugin release is replaced by a newer corrective release, never by rewriting the installed cache.

## Nix maintenance and encrypted secrets

Both hosts use the [shared Nix policy](modules/shared/nix-policy.nix) for pinned registries and disabled legacy channels. On the Mac, Determinate Nix owns automatic store garbage collection; this configuration does not schedule an optimiser. On Korolev, NixOS owns weekly garbage collection and store optimisation. Keep generations needed for recovery before collecting store paths.

The Mac's [SOPS user module](modules/home/darwin/secrets.nix) decrypts committed secrets with its private age key at `~/.config/sops/age/keys.txt`. Never commit, print, or copy that key or decrypted values into this repository. The repository check rejects plaintext secret values outside SOPS metadata. Offline recovery is **not yet configured**: the owner must create a key on encrypted offline media, provide only its public recipient, and verify each re-encrypted file with that key before treating offline recovery as available. Do not remove the current ciphertext until the Mac can decrypt replacements.

## DNS

[`dns/dnsconfig.js`](dns/dnsconfig.js) declares the `glockyco.com` zone. `nix flake check` validates it on both systems without a token or provider access, and any DNSControl warning fails the check. Checks and activation never publish the zone.

Publish only from the Mac, after a review of the preview. Each command starts the development shell first and reads the decrypted DNS token inside it, so only DNSControl receives the token and nothing prints it:

```sh
cd dns
nix develop .. --command bash -c 'CLOUDFLARE_API_TOKEN="$(< ~/.config/sops-nix/secrets/cloudflare-dns-token)" exec dnscontrol preview'
nix develop .. --command bash -c 'CLOUDFLARE_API_TOKEN="$(< ~/.config/sops-nix/secrets/cloudflare-dns-token)" exec dnscontrol push'
```

Only the owner runs `push`, and only after the preview shows the intended record changes and nothing else. An agent may run `preview` but never `push`. A project that needs the token in its own shell calls the `use_cloudflare_dns` direnv function from its `.envrc`.

## Update

The central [dependency automation](https://github.com/glockyco/dependency-automation) opens review-only Nix-input PRs every Saturday. Renovate updates GitHub Actions. Neither merges or activates hosts. Plannotator stays at an explicitly selected vendor revision. [Dependency operations](docs/operations/dependency-updates.md) covers on-demand Plannotator updates, external authorization, and release recovery.

For a manual Nix update, choose one command, review the diff, then run the gates above:

```sh
nix flake update                       # all inputs
nix flake update personal-omp-plugin   # OpenSpec check tools only
```

The `personal-omp-plugin` input supplies only the fleet OpenSpec contract check and the adapter-freshness check; updating it does not change the plugin that hosts run. OMP and the plugin update with their own commands, described under [OMP](#omp).

## Recover

Keep the previous generation until all applicable gates and smoke checks pass. List and restore Nix generations on the affected host:

```sh
# macOS
sudo darwin-rebuild --list-generations | cat
sudo darwin-rebuild --rollback

# Korolev
sudo nixos-rebuild list-generations | cat
sudo nixos-rebuild switch --rollback --no-reexec
```

Then repeat verification. Nix rollback restores Nix-managed tools, not OMP or plugin versions, credentials, tailnet enrollment, or application data; use the [OMP](#omp) commands for those. Windows configuration has no generation rollback.
