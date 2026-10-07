# Provision and recover korolev

Use this procedure for a new secondary NixOS WSL import or Linux builder recovery. Native Windows bootstrap and user apply live in [Korolev native Windows operations](korolev-windows.md).
Windows owns native applications and employer policy. NixOS owns Linux system configuration, system-declared user packages and shell plugins; chezmoi owns user files independently on each platform.
OMP comes from the official installer and owns authentication, sessions, databases, its plugin cache, browser downloads, profiles, and caches.
Keep secondary Linux repositories in the Linux home directory, not `/mnt/c`; native Windows repositories use the separate Windows `~/src`.

**Account boundary:** Import, activation, generation rollback, and distribution rollback use the standard Windows account.
The Windows document and chezmoi also use that account. Only the approved Zen/Tailscale installers, Zen policy script and native Neo driver installation require separate Administrator credentials.
The policy script owns only Zen's policy file under Program Files.
The driver script owns only the native Neo DLLs and keyboard-layout registration.
ReNeo separately requests those credentials at each sign-in for its runtime process.
Do not copy another host's credentials or bypass employer policy.

## Import the host

Enable WSL 2 through Microsoft-supported or employer-managed channels. Use the accepted terminal; this procedure does not install or manage Windows Terminal.
Confirm the Windows prerequisites:

```powershell
wsl --version
wsl --list --verbose
$env:PROCESSOR_ARCHITECTURE
```

Require `AMD64` from 64-bit PowerShell. Stop on another architecture: this procedure supports only `x86_64-linux` WSL.

On the image builder, confirm the architecture before making changes:

```sh
uname -m
```

Stop unless the result is `x86_64`. The builder needs Nix and flakes, such as in the previous WSL distribution.
Build the reviewed revision:

```sh
nix build .#nixosConfigurations.korolev.config.system.build.tarballBuilder
sudo ./result/bin/nixos-wsl-tarball-builder
```

The builder writes `nixos.wsl` in the working directory without a repository checkout.
The Mac cannot cross-build this Linux system.
Before either host configuration exists, configure the [declared cache and signing key](../../modules/shared/binary-caches.nix) in the builder's Nix settings.
Alternatively, pass both through `--extra-substituters` and `--extra-trusted-public-keys` as a trusted user.
An untrusted user cannot add a signing key and must compile instead.

Import without elevation. Keep the previous distribution registered until all acceptance gates pass:

```powershell
wsl --install --from-file nixos.wsl
wsl --list --verbose
```

The new distribution is `NixOS`, under `%LOCALAPPDATA%\WSL\NixOS`.
Start it and confirm `systemd`, the [declared user](../../hosts/korolev/default.nix), and `x86_64`:

```sh
ps -p 1 -o comm=
whoami
uname -m
```

Stop if PID 1 is not `systemd`.
Run only one distribution at a time: WSL distributions share the user-manager cgroup.
From Windows, terminate the previous distribution.
Replace `<previous-distribution>` with its registered name here and in the recovery procedure:

```powershell
wsl --terminate '<previous-distribution>'
```

Termination returns before the shared cgroup is necessarily free. In NixOS, require an active user manager before activation:

```sh
systemctl is-active user@1000.service
```

If the unit is failed or inactive after the other distribution stops, recover it:

```sh
sudo systemctl reset-failed user@1000.service
sudo systemctl start user@1000.service
```

An occupied cgroup causes `Device or resource busy`. An absent user bus causes `Failed to open dbus connection` during activation.

## Prepare the checkout and authentication

Clone under the personal Git include, not directly under `~/src`:

```sh
mkdir -p "$HOME/src/github.com/glockyco"
git clone https://github.com/glockyco/nix-config.git "$HOME/src/github.com/glockyco/nix-config"
cd "$HOME/src/github.com/glockyco/nix-config"
git config user.email
```

The email must be `11704293+glockyco@users.noreply.github.com`. Every repository below `~/src/github.com/` uses this address. Repositories below `~/src/gitlab.scch.at/` and other locations use the global employer address unless the repository declares a local override.
Use the reviewed, published revision. An older checkout can activate successfully while dropping newer configuration.
Follow [Develop](../../README.md#develop) and [Activate](../../README.md#activate), then install OMP and the personal plugin as described under [OMP](../../README.md#omp).
Activation does not install or invoke OMP, and does not apply user files. After the system switch, initialize chezmoi from this checkout with `chezmoi init --source "$PWD" --promptString host=korolev`, review the ordinary diff, then run `chezmoi apply` and `chezmoi verify` as the user. Mac credentials are excluded; SSH/GPG identities, gh hosts.yml, shell history and OMP state remain unmanaged.
Confirm the activated host:

```sh
nixos-version --configuration-revision
systemctl is-system-running
systemctl --failed --no-legend --plain
```

Require the reviewed revision, `running`, and no failed units.
Start `omp` and complete fresh interactive subscription logins for Anthropic and OpenAI.
Confirm each login with one real response from its provider. Do not transfer authentication databases or tokens.

Authenticate GitHub through the host's HTTPS credential helper:

```sh
gh auth login --hostname github.com --git-protocol https --web
gh auth status
gh api user --jq '.login'
git ls-remote https://github.com/glockyco/nix-config HEAD
```

Chezmoi's `config.yml` is a regular user-writable file; `hosts.yml` remains gh-owned authentication state. The declaration restores HTTPS on apply. A read-only-file error now indicates a cutover conflict, not an expected steady-state result; inspect the backed-up path/symlink manifest instead of suppressing it.

### Enroll HTTPS Git credentials in WSL

Korolev provides Git Credential Manager, GnuPG, `pass`, and curses pinentry through Nix. `pass` stores tokens as GPG-encrypted files in user state, not in the Nix store. The WSLg keyring password dialog does not accept input on this host, so use terminal pinentry instead.

In a WSL terminal, create one GPG key with a nonempty passphrase and initialize the password store with its fingerprint:

```sh
gpg --quick-generate-key 'Git credentials <your-address@example.com>' default default never
gpg --list-secret-keys --fingerprint
pass init FINGERPRINT
```

Replace the example address and fingerprint with your own values. Keep the private key and its passphrase outside the repository. If the private key is lost, the encrypted token cannot be recovered; generate a new Overleaf token and enroll it again.

For an Overleaf checkout that has a local cache helper override, remove that override. Fetch once in a WSL terminal:

```sh
git -C /path/to/overleaf-checkout config --local --unset-all credential.helper
git -C /path/to/overleaf-checkout fetch origin
```

If pinentry asks for a passphrase, enter the GPG key passphrase. If Git asks for an Overleaf password, paste the Git authentication token. Do not put either secret in a command, Git URL, or repository. The remote uses the `git` username. These are secondary Linux credentials, not Windows GCM; native Fork uses its separate Windows-local Git configuration.

Verify access without a terminal prompt:

```sh
GIT_TERMINAL_PROMPT=0 git -C /path/to/overleaf-checkout ls-remote origin HEAD
```

After a WSL restart or GPG agent cache expiry, open a WSL terminal and run `gpg-connect-agent updatestartuptty /bye` before the lookup. Unlock the key at the terminal prompt, then use Fork. The token remains encrypted on disk and does not need to be entered again until it expires or is revoked. Do not use Git's plaintext `store` helper.

Run the [release smoke](dependency-updates.md#release-smoke) in a disposable WSL repository in a Tern session that runs NixOS.
Record the tested Terminal, Windows, WSL, and NixOS versions, host architecture, and locked repository revision.
Then run the browser smoke below.
Do not force terminal image, keyboard, width, or redraw environment variables to make acceptance pass.

## Managed-browser smoke

In a fresh OMP session, request:

```text
Use OMP's managed browser, not the browser relay. Open https://example.com, report the page title, capture a screenshot, and close the browser.
```

Require the title `Example Domain` and a screenshot of the same page, without a missing-library error.
Repeat after OMP updates, OMP recovery, or activation changes to the browser ABI.
NixOS supplies the [loader and libraries](../../modules/roles/nixos/wsl-workstation/programs.nix), not Chromium downloads or browser profiles.

## Join the tailnet and provision the builder

Use tailnet `glockyco.github`, ID `TEHFqtX6D121CNTRL`, with MagicDNS enabled.
Its DNS domain is in the [shared declaration](../../modules/shared/default.nix).
After first activation, restart NixOS from Windows so WSL releases resolver ownership:

```powershell
wsl --terminate NixOS
```

Reopen NixOS and confirm Windows DNS tunneling remains the global upstream:

```sh
resolvectl status
getent ahosts github.com
```

Require the [declared resolver](../../modules/roles/nixos/wsl-workstation/wsl.nix), `10.255.255.254`.
If employer-internal services are used from WSL, also resolve a known employer hostname. Otherwise, that check is not applicable.
Join once with the declared tag and complete the displayed browser login:

```sh
sudo tailscale up --advertise-tags=tag:korolev
tailscale status
tailscale debug prefs
getent ahosts macbook-pro
```

Require `tag:korolev`, `ShieldsUp: true`, and a Mac address within `100.64.0.0/10`.

The Nix daemon uses root's dedicated key, not the interactive user's credentials.
Keep the private key outside Git and the Nix store. Activation must never generate or replace it.
Create it only if absent:

```sh
sudo install -d -m 700 /root/.ssh
sudo test ! -e /root/.ssh/macbook-pro-builder &&
  sudo ssh-keygen -t ed25519 -N '' -C korolev-builder -f /root/.ssh/macbook-pro-builder
sudo stat -c '%U %a %n' /root/.ssh /root/.ssh/macbook-pro-builder
sudo ssh-keygen -y -f /root/.ssh/macbook-pro-builder
```

Require root ownership, directory mode `700`, and private-key mode `600`.
Review the printed public key against the Mac's [restricted authorization](../../modules/roles/darwin/desktop/tailscale.nix) before activation.
Never overwrite an existing private key to make bootstrap pass.
The client pins the Mac's actual OpenSSH host key, not a Tailscale SSH key.
If it changes, verify the replacement from a local Mac terminal before editing the [pin](../../modules/roles/nixos/wsl-workstation/programs.nix).
Never disable strict host checking or accept an unverified key.

### Verify or recover builder access

Build both systems and merge the reviewed configuration before Mac activation.
Keep a local Mac administrator terminal and the previous Nix generation available.
After [Mac activation](../../README.md#activate), inspect the native service there:

```sh
tailscale debug prefs
sudo systemsetup -getremotelogin
sudo launchctl print system/org.nixos.tailnet-sshd
sudo lsof -nP -a -c sshd -iTCP:22 -sTCP:LISTEN
sudo /usr/bin/stat -f '%Sp %Su:%Sg %N' \
  /var/lib/tailnet-sshd /var/lib/tailnet-sshd/authorized_keys \
  /var/lib/tailnet-sshd/authorized_keys/glockyco
sudo realpath /var/lib/tailnet-sshd/authorized_keys/glockyco
```

Require `RunSSH: false`, Remote Login off, and listening addresses only on the Mac's tailnet interface.
Require a regular `root:wheel` authorization file and `root:wheel` directories with mode `755`.
Its canonical path must stay under `/var/lib/tailnet-sshd`, outside `/nix/store`.
Apple's Remote Login socket ignores `ListenAddress`. An unprivileged smoke server does not prove this root service's public-key/PAM boundary.

After WSL activation with the existing credential, inspect and exercise root's client:

```sh
sudo ssh -G macbook-pro
sudo ssh macbook-pro 'command -v nix-daemon'
sudo ssh macbook-pro 'exit 23'
printf 'SSH status: %s\n' "$?"
tailnet-builder-check
```

Compare effective settings with the [client declaration](../../modules/roles/nixos/wsl-workstation/programs.nix), including strict checking, the dedicated identity, and bounded batch connections.
Require `/nix/var/nix/profiles/default/bin/nix-daemon`, status `23`, and a fresh builder result naming `arm64`, `macbook-pro`, and `passed`.
The builder check also reports the measured Tailscale path.
For authentication failures, collect native Mac logs without changing the daemon's log level:

```sh
sudo /usr/bin/log show --last 10m --style compact --info \
  --predicate 'process BEGINSWITH "sshd"'
```

The restricted key forbids PTYs and forwarding but permits arbitrary commands as the Mac user, who is trusted by Nix.
`restrict` is not a command sandbox. After compromise, revoke its public authorization, replace the private key locally, and review the replacement public key.

Exercise disconnected-builder recovery only with the local Mac recovery terminal available.
Require failure within the configured connection timeout, restore connectivity, and run a fresh builder check.
If recovery fails, roll back locally. Nix rollback neither restores keys nor changes Tailscale enrollment.

## Native Windows setup

Windows is the primary workstation; this page retains the secondary WSL import, Linux activation and builder procedures. Use the separate native checkout at `C:\Users\jglock\src\github.com\glockyco\nix-config`, not the Linux checkout for Windows user setup.

Follow [Korolev native Windows operations](korolev-windows.md) for standard-user Git/chezmoi bootstrap, native checks, Neo restart prerequisite, `chezmoi diff/apply/verify`, explicit Zen/Tailscale installer prompts and narrow Administrator operations. There is no Nix-built Windows artifact or Windows generation rollback.

The same runbook owns [native Zed/Fork/Git and Mac LaTeX](korolev-windows.md#native-projects-and-mac-latex), [Tern/OMP/plugin/annotation](korolev-windows.md#explicit-tern-omp-plugin-and-annotation-flows), and [local backup/drift repair/recovery](korolev-windows.md#manual-preferences-and-nontransactional-recovery). Windows user files have one chezmoi owner; application profiles, credentials and runtime databases remain unmanaged. Open Windows repositories locally in Zed and Fork; do not restore the old WSL Git bridge or WSL editor transport.

## Recover Linux state

Use [Recover](../../README.md#recover) for generation listing and rollback.
The WSL rollback requires `--no-reexec`: rollback accepts no flake reference, and re-execution otherwise searches for an absent `nixos-config`.
To select a specific retained generation:

```sh
sudo nix-env -p /nix/var/nix/profiles/system --switch-generation <number>
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
```

A failed activation can register a generation while the previous closure remains active.
After rollback, delete only the rejected generation if needed:

```sh
sudo nix-env -p /nix/var/nix/profiles/system --delete-generations <number>
```

Before removing the previous distribution, rollback can instead switch distributions from Windows:

```powershell
wsl --terminate NixOS
wsl --distribution '<previous-distribution>'
```

After its removal, use retained NixOS generations.
Nix rollback restores system configuration and the system-declared user packages, not chezmoi destinations, OMP or writable runtime state. Select the previous reviewed chezmoi source revision and apply/verify it separately as the ordinary user; initial-cutover rejection additionally restores the captured Home Manager files/symlinks/permissions and original chezmoi state from local backups.
Use [OMP recovery](dependency-updates.md#omp-recovery) for OMP and the plugin.
Do not delete `~/.omp`, edit `/etc/nixos`, or run `nix flake update` as recovery.
