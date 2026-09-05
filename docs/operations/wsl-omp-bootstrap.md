# Provision and recover korolev

Use this procedure for a new NixOS WSL import, Windows setup, or builder recovery.
Windows owns native applications and employer policy. NixOS owns Linux system and user configuration.
The official installer owns the OMP executable. OMP owns authentication, sessions, databases, browser downloads, profiles, and caches.
Keep repositories in the Linux home directory, not `/mnt/c`.

**Account boundary:** Import, activation, generation rollback, and distribution rollback use the standard Windows account.
The Windows document also uses that account. Only the Zen installer, Zen policy script, and native Neo driver installation require Administrator credentials.
The policy script owns only Zen's policy file under Program Files.
The driver script owns only the native Neo DLLs and keyboard-layout registration.
ReNeo separately requests those credentials at each sign-in for its runtime process.
Do not copy another host's credentials or bypass employer policy.

## Import the host

Install Windows Terminal Stable and enable WSL 2 through Microsoft-supported or employer-managed channels.
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

The email must be `11704293+glockyco@users.noreply.github.com`. Other locations use the global employer address.
Use the reviewed, published revision. An older checkout can activate successfully while dropping newer configuration.
Follow [Develop](../../README.md#develop), then the WSL OMP installer under [Update](../../README.md#update) and [Activate](../../README.md#activate).
Activation reconciles Herdr but does not install or invoke OMP.
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

`gh auth login` can report `read-only file system` after authentication when it writes the Nix-owned `config.yml`.
The token remains in writable `hosts.yml`, and the host already declares HTTPS. Accept this only if the verification commands succeed.
Run the [wrapped-session release smoke](dependency-updates.md#release-smoke) in a disposable WSL repository through Windows Terminal Stable.
Record the tested Terminal, Windows, WSL, and NixOS versions, host architecture, and locked repository revision.
Then run the browser smoke below.
Do not force terminal image, keyboard, width, or redraw environment variables to make acceptance pass.

## Managed-browser smoke

In a fresh wrapped OMP session, request:

```text
Use OMP's managed browser, not the browser relay. Open https://example.com, report the document heading, capture a screenshot, and close the browser.
```

Require `Example Domain` and a screenshot of the same page, without a missing-library error.
Repeat after OMP updates, OMP recovery, or activation changes to the browser ABI.
NixOS supplies the [loader and libraries](../../modules/nixos/programs.nix), not Chromium downloads or browser profiles.

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

Require the [declared resolver](../../modules/nixos/wsl.nix), `10.255.255.254`.
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
Review the printed public key against the Mac's [restricted authorization](../../modules/darwin/tailscale.nix) before activation.
Never overwrite an existing private key to make bootstrap pass.
The client pins the Mac's actual OpenSSH host key, not a Tailscale SSH key.
If it changes, verify the replacement from a local Mac terminal before editing the [pin](../../modules/nixos/programs.nix).
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

Compare effective settings with the [client declaration](../../modules/nixos/programs.nix), including strict checking, the dedicated identity, and bounded batch connections.
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

## Apply the Windows layer

Close all Windows Terminal windows after import, then reopen Terminal so its WSL generator discovers `NixOS`.
The artifact selects that generated profile without replacing the profile list.
Build the reviewed [Windows artifact](../../modules/windows/default.nix) in NixOS.
Use an absent destination under writable `C:\Temp`. Do not merge the artifact into a stale copy.

```sh
nix build .#windows-configuration
cp -rL result /mnt/c/Temp/windows-configuration
```

In standard PowerShell, enable WinGet Configuration and set the paths:

```powershell
winget configure --enable
$configuration = 'C:\Temp\windows-configuration\configuration.winget'
$kbdNeo = 'C:\Temp\windows-configuration\apply-kbdneo.ps1'
$zenPolicies = 'C:\Temp\windows-configuration\apply-zen-policies.ps1'
```

Test all artifacts before the first apply:

```powershell
winget configure test --file $configuration --accept-configuration-agreements --disable-interactivity --suppress-initial-details
powershell -NoProfile -ExecutionPolicy Bypass -File $kbdNeo -Test
powershell -NoProfile -ExecutionPolicy Bypass -File $zenPolicies -Test
```

Exit status `1` means drift, not an acceptable resource error. Require an elevation shield only on `package browser`.
If only Brave reports drift because a security update exceeds the pin, review an updated declaration.
Do not disable browser updates or force a downgrade.

Open 64-bit PowerShell with **Run as administrator**, using the separate local `Administrator` credential:

```powershell
$kbdNeo = 'C:\Temp\windows-configuration\apply-kbdneo.ps1'
powershell -NoProfile -ExecutionPolicy Bypass -File $kbdNeo
powershell -NoProfile -ExecutionPolicy Bypass -File $kbdNeo -Test
```

Require `kbdneo: desired` after installation. Restart Windows before applying the document or selecting the layout.
After restart, reset the paths in standard PowerShell and apply the document there:

```powershell
winget configure --file $configuration --accept-configuration-agreements --disable-interactivity --suppress-initial-details
```

Enter the separate Administrator credential only when the Zen installer requests it.
Do not run the document as Administrator: that account has a different profile and cannot use the interactive user's DSC package.
Sign out and sign in after the first apply. This applies the UI language and starts ReNeo's elevation launcher.
Enter the Administrator credential at its prompt, including at subsequent sign-ins.
If sign-out must wait, select `Deutsch (Neo)` with `Win+Space` and start the launcher from standard PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\WindowsConfiguration\start-reneo-elevated.ps1"
```

The native driver supplies UAC's base layout. Elevated ReNeo supplies higher layers in ordinary and elevated applications, not UAC.
In Administrator PowerShell, apply only the Zen policy file:

```powershell
$zenPolicies = 'C:\Temp\windows-configuration\apply-zen-policies.ps1'
powershell -NoProfile -ExecutionPolicy Bypass -File $zenPolicies
```

Repeat all three tests from the standard session. Require the described state, `kbdneo: desired`, and `Zen policies: desired`.
Reapply each artifact in its original account context and require no changes.

**CAUTION: DSC has no generation or transactional rollback.** An interrupted apply can leave earlier resources changed.
After failure, inspect the reported error and applied state before revising and reapplying the artifact.
A repository revert neither restores old files nor uninstalls applications unless the declaration explicitly requests that state.
NixOS rollback affects only Linux state.

### Manual Windows settings

- Use **Settings > Apps > Default apps** for associations. Windows protects them with a generated `UserChoice` hash.
  Bind `.pdf` to Adobe Acrobat. Bind these extensions to Zed:
  `.nix`, `.md`, `.json`, `.yaml`, `.yml`, `.toml`, `.sh`, `.ps1`, `.py`, `.js`, `.ts`, `.tsx`, `.rs`, `.go`, `.diff`, `.patch`, `.txt`.
  Keep the LaTeX previewer decision unresolved.
- Keep taskbar pins under user control. Supported taskbar layout policy would replace or control the user's pin list.
- Keep **Country or region** set to Austria. Widgets uses that region for German hosted cards and weather, without an independent content-language control.
- Set **Settings > System > Display > Night light** to sunset-to-sunrise at 50% strength.
  Its undocumented CloudStore binary format is outside the declaration.
- Leave employer-managed applications to device management. Do not add a competing installer or configuration owner.

### Configure and verify the browser relay

Confirm Brave installation in standard PowerShell with `winget list --id Brave.Brave --exact`.
From NixOS, install OMP's unpacked extension into Windows LocalAppData:

```sh
windows_local_app_data="$(
  powershell.exe -NoProfile -Command \
    '[Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)' |
    tr -d '\r'
)"
relay_extension="$(wslpath "$windows_local_app_data")/OMP/browser-relay-extension"
omp browser-relay install --dir "$relay_extension"
wslpath -w "$relay_extension"
```

Open Brave manually with a dedicated `OMP Relay` profile.
At `brave://extensions`, enable **Developer mode**, choose **Load unpacked**, and select the printed Windows path.
Do not install the extension in an employer-managed browser profile or add Brave or the relay to startup.
Keep only the intended page open. From an OMP session in NixOS, request:

```text
Use the browser relay, not the managed browser. Adopt the current Brave tab, report its title and URL, capture a screenshot, and leave the page unchanged.
```

Require a title, URL, and screenshot that match the visible tab. Close Brave afterward.
The extension and profile remain mutable OMP/browser state. Use them only for tasks that require an authenticated Windows browser.
After the next Windows restart, before starting Brave or OMP, check from standard PowerShell:

```powershell
Get-Process brave -ErrorAction SilentlyContinue
wsl --distribution NixOS -- pgrep -af 'omp browser-relay'
```

Require no process output. `pgrep` status `1` means the relay is off, even after NixOS starts.

### Verify native integration

In Zed, use `projects: open wsl`, select `NixOS`, and open `/home/user/src/github.com/glockyco/nix-config`.
Do not open the UNC path as a local folder: that gives Linux ACP agents a Windows working directory.
Confirm these live boundaries after sign-in:

- Zed starts `nixd` and wrapped `omp acp` inside NixOS without SSH. Fork uses the declared `wslgit` bridge.
- Windows Terminal opens NixOS at the Linux home, with working font glyphs.
- Neo works in ordinary applications, elevated applications, and UAC, with the higher-layer boundary described above.
- Command Palette launches applications and switches windows. Its PowerToys parent remains the sole startup owner.
  After a PowerToys pin change, compare the enabled and disabled module lists with the installed version.
- AltSnap modifier-drag moves windows and performs 50/50 edge or corner snapping.
- Zen shows the declared theme. Windows and PowerToys use English, with ISO dates and the regional Widgets exception above.

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
Nix rollback restores system and user configuration together, not OMP's executable or writable state.
Use [OMP version recovery](dependency-updates.md#omp-version-recovery) for that executable.
Do not delete `~/.omp`, edit `/etc/nixos`, or run `nix flake update` as recovery.
Herdr alone owns `~/.omp/agent/extensions/herdr-omp-agent-state.ts`.
