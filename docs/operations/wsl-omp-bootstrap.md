# Provision the korolev NixOS WSL host

## Scope

This procedure makes an `x86_64` Windows work machine run the NixOS host `korolev` under WSL 2. Three layers own separate state.

| Layer                | Owns                                                                                        |
| -------------------- | ------------------------------------------------------------------------------------------- |
| Windows              | Windows Terminal, WSL enablement, employer policy, native applications, and the editor      |
| NixOS host `korolev` | Linux system scope, user scope, OMP wrapper and plugin, Herdr, OpenSpec, and language tools |
| OMP binary installer | the user-local oh-my-pi executable                                                          |
| OMP                  | authentication, configuration, sessions, history, caches, logs, and databases               |

Repositories stay under the Linux home directory, not under `/mnt/c`.

This procedure does not approve external providers, copy credentials from another host, or manage project toolchains. The Windows section installs the declared native applications after the NixOS host is active.

Distribution import, NixOS activation, generation rollback, and distribution rollback run as the standard Windows user. The Windows configuration also uses that account except for three marked operations: the official Zen installer, its policy file, and the native Neo keyboard driver require the separate local `Administrator` credential.

## 1. Confirm the prerequisites

Install or update Windows Terminal Stable through the Microsoft-supported or employer-managed channel. Confirm WSL 2 and the architecture:

```powershell
wsl --version
wsl --list --verbose
```

The image build needs one `x86_64-linux` machine with Nix and flakes. The Darwin host cannot cross-build an `x86_64-linux` system, so the existing WSL distribution builds the first image.

## 2. Build the distribution image

Check out the reviewed revision on the `x86_64-linux` machine and run:

```sh
nix build .#nixosConfigurations.korolev.config.system.build.tarballBuilder
sudo ./result/bin/nixos-wsl-tarball-builder
```

The builder writes `nixos.wsl` into the working directory. The image carries the reviewed system closure and no repository checkout.

This flake declares no `nixConfig`, so a machine that has neither host configuration reaches the Numtide cache only through its own Nix settings. Pass both values as a trusted user, or state them in `/etc/nix/nix.conf`:

```sh
nix build \
  --extra-substituters https://cache.numtide.com \
  --extra-trusted-public-keys niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g= \
  .#nixosConfigurations.korolev.config.system.build.tarballBuilder
```

Nix discards a command-line signing key for a user who is not in `trusted-users`. Such a user compiles the closure instead of substituting it.

## 3. Import the distribution

Import without elevation, and keep the previous distribution registered:

```powershell
wsl --install --from-file nixos.wsl
```

The import creates the distribution `NixOS` under `%LOCALAPPDATA%\WSL\NixOS`. Confirm that both distributions are registered:

```powershell
wsl --list --verbose
```

## 4. Confirm the imported host

Start the new distribution and confirm the process tree and the declared user:

```sh
ps -p 1 -o comm=
whoami
uname -m
```

The results must be `systemd`, the declared user name, and `x86_64`. Stop if the first result is not `systemd`.

## 5. Run one distribution at a time

WSL puts no distribution in its own cgroup namespace. Every running distribution targets `/user.slice/user-1000.slice/user@1000.service`, and the second one to start cannot attach. The user manager then fails with `Failed to spawn executor: Device or resource busy`, and `nixos-rebuild switch` fails at its user unit reload.

Stop the other distribution from Windows:

```powershell
wsl --terminate Ubuntu-26.04
```

That command returns before the shared cgroup is released. A distribution that had run for one hour still held the path 70 seconds after the command returned. The cgroup directory also stays visible with an empty `cgroup.procs`, because the processes that hold it belong to another PID namespace.

The gate is therefore the observed unit state, not the return of the termination command:

```sh
systemctl is-active user@1000.service
```

The result must be `active`. Start the unit when it reports `failed` or `inactive`:

```sh
sudo systemctl reset-failed user@1000.service
sudo systemctl start user@1000.service
```

A dead user manager fails an activation a second way. The switch reports `Failed to open dbus connection` and `user activation for user failed`, because no user bus socket exists.

## 6. Clone the repository

A personal clone belongs under the tree that the conditional Git include names. `programs.git.settings.ghq.root` is `~/src`, and ghq lays a clone out as `~/src/<host>/<owner>/<repo>`:

```sh
mkdir -p "$HOME/src/github.com/glockyco"
git clone https://github.com/glockyco/nix-config.git "$HOME/src/github.com/glockyco/nix-config"
cd "$HOME/src/github.com/glockyco/nix-config"
git config user.email
```

The result must be `11704293+glockyco@users.noreply.github.com`. A clone in another location, such as directly under `~/src`, reports the global work address instead.

The clone must resolve the published revision. Publish the reviewed revision before the first activation inside the distribution. A clone of an older remote activates cleanly and silently drops every later change.

Entering the clone installs the commit hook. `direnv` enters the development shell for this system, and the shell installs the hook into the working tree:

```sh
direnv allow
test -f .git/hooks/pre-commit && printf '%s\n' 'commit-gate=installed'
```

Run `nix develop --command true` instead when `direnv` is not active. A host with no development shell for its system installs no hook, and a commit there passes no formatting gate and reports nothing.

## 7. Install OMP and activate the host

Install the official prebuilt oh-my-pi release at the wrapper's fixed user-local target. The explicit `--binary` mode prevents a Bun source installation:

```sh
curl -fsSL https://omp.sh/install \
  | PI_INSTALL_DIR="$HOME/.local/lib/oh-my-pi" sh -s -- --binary
"$HOME/.local/lib/oh-my-pi/omp" --version
```

Activate from a committed tree:

```sh
sudo nixos-rebuild switch --flake .#korolev
```

Home Manager reconciles Herdr during activation. It does not install, update, or invoke the mutable OMP executable. Verify the complete wrapped environment explicitly:

```sh
verify-personal-omp
```

The verifier prints the observed OMP version, the immutable plugin path, and `omp: current`.

Confirm the host result:

```sh
sudo nixos-rebuild list-generations | cat
nixos-version --configuration-revision
systemctl is-system-running
systemctl --failed --no-legend --plain | cat
herdr integration status
```

The system must report `running` with no failed unit. A dirty worktree marks the generation revision with a `-dirty` suffix, and each edit produces another closure. A second activation of the same clean revision registers no second generation.

To update OMP later, rerun the binary installer command and then run `verify-personal-omp`. No Nix activation is required. To recover release `v<version>`, use the same target with an explicit tag:

```sh
curl -fsSL https://omp.sh/install \
  | PI_INSTALL_DIR="$HOME/.local/lib/oh-my-pi" sh -s -- --binary --ref v<version>
verify-personal-omp
```

## 8. Authenticate providers

Start OMP and use its interactive login:

```sh
omp
```

Complete fresh subscription logins for Anthropic and OpenAI. Do not copy authentication databases or tokens from another host. OMP stores the OAuth credentials as the providers `anthropic` and `openai-codex` in `~/.omp/agent/agent.db`.

Confirm each provider with one real model response:

```sh
omp -p --no-session --no-tools --model opus "Reply with exactly: ANTHROPIC OK"
omp -p --no-session --no-tools --model openai-codex/gpt-5.4-mini "Reply with exactly: OPENAI OK"
```

## 9. Authenticate GitHub

This host holds no GitHub key, so `gh` drives Git over HTTPS and answers the Git credential prompt through its declared helper:

```sh
gh auth login --hostname github.com --git-protocol https --web
```

The command stores the token in `~/.config/gh/hosts.yml`, which stays writable. It then tries to write `git_protocol` into `~/.config/gh/config.yml`, which Nix owns, so it reports `read-only file system` and exits with status 1 after the authentication completes. The host already declares `https`, so that failure needs no action.

Confirm the result:

```sh
gh auth status
gh api user --jq '.login'
git ls-remote https://github.com/glockyco/nix-config HEAD
```

## 10. Run the real-session smoke

Create a disposable repository and start the wrapper:

```sh
mkdir "$HOME/src/omp-wsl-smoke"
cd "$HOME/src/omp-wsl-smoke"
git init --initial-branch=main
omp
```

Ask OMP:

```text
This is the WSL release smoke. Do not modify the repository.

1. Report the exact source path of the loaded @glockyco/personal-omp-plugin.
2. Quote the personal commit policy that applies to creating and amending commits.
3. Call personal_commit with action=preview, subject="chore: verify WSL smoke", body="The WSL installation must prove that the immutable personal commit extension loads without changing repository state.", and repo=".".
4. Report whether the preview changed the repository.
```

The plugin path must be under `/nix/store`. The policy and `personal_commit` tool must be active. After leaving OMP, confirm that the preview created no state:

```sh
git status --short
git log --oneline 2>&1 || true
```

The status output must be empty, and Git must report that `main` has no commits.

OMP documents these Windows Terminal fallback chords. Use them only when the terminal handles the normal chord:

| Operation                     | OMP fallback  |
| ----------------------------- | ------------- |
| Paste image or clipboard text | `Alt+V`       |
| Queue a follow-up             | `Ctrl+Q`      |
| Raw text paste                | `Alt+Shift+V` |

Do not force terminal image, keyboard, width, or redraw environment variables for the smoke.

## 11. Prepare the Windows Terminal profile

Windows Terminal enumerates WSL distributions when its process starts, so a distribution imported later is absent from a running window. Close every Windows Terminal window and start Terminal again. The `Microsoft.WSL` generator then adds a `NixOS` profile with its own GUID. The Windows configuration discovers that GUID, makes the profile the default, and preserves the generated profile list.

## 12. Apply the Windows layer

Build the reviewed artifact in NixOS, then copy its files into a writable Windows directory:

```sh
nix build .#windows-configuration
chmod -R u+w /mnt/c/Temp/windows-configuration 2>/dev/null || true
rm -rf /mnt/c/Temp/windows-configuration
cp -rL result /mnt/c/Temp/windows-configuration
```

Enable WinGet Configuration once. The artifact has one document and two narrow Administrator scripts. WinGet 1.29.290 displays the declared elevation shield but does not change a DSC script resource's token on this machine. The separate Administrator account also cannot use the interactive user's per-user DSC package. The official Zen installer can elevate itself, so the document owns the package. The generated scripts own only `C:\Program Files\Zen Browser\distribution\policies.json` and the native Neo DLLs and keyboard-layout registration.

Set the artifact paths in a standard PowerShell session:

```powershell
winget configure --enable
$configuration = 'C:\Temp\windows-configuration\configuration.winget'
$kbdNeo = 'C:\Temp\windows-configuration\apply-kbdneo.ps1'
$zenPolicies = 'C:\Temp\windows-configuration\apply-zen-policies.ps1'
```

Test all three artifacts before the first apply. Exit status 1 means that the test found drift; resource errors are not expected. The WinGet output must show a shield on exactly `package browser`.

```powershell
winget configure test `
  --file $configuration `
  --accept-configuration-agreements `
  --disable-interactivity `
  --suppress-initial-details
powershell -NoProfile -ExecutionPolicy Bypass -File $kbdNeo -Test
powershell -NoProfile -ExecutionPolicy Bypass -File $zenPolicies -Test
```

Open 64-bit Windows PowerShell with **Run as administrator**. Authenticate with the separate local `Administrator` credential, set `$kbdNeo` again, and install the native keyboard driver:

```powershell
$kbdNeo = 'C:\Temp\windows-configuration\apply-kbdneo.ps1'
powershell -NoProfile -ExecutionPolicy Bypass -File $kbdNeo
powershell -NoProfile -ExecutionPolicy Bypass -File $kbdNeo -Test
```

The first command must report `kbdneo: changed; restart Windows before selecting the layout`; the test must then report `kbdneo: desired`. Restart Windows before you apply the document.

After the restart, set the three paths again in a standard PowerShell session. Apply the document from that session. Enter the separate local `Administrator` credential only if the Zen installer requests it.

```powershell
winget configure `
  --file $configuration `
  --accept-configuration-agreements `
  --disable-interactivity `
  --suppress-initial-details
```

The document puts English (United Kingdom) first in the preferred language list and sets it as the Windows UI override, but leaves that entry without an input method. It preserves the `de-DE` and `de-AT` entries, adds `Deutsch (Neo)` to the German input methods, and makes Neo the default. The document sets the short date to ISO 8601 `yyyy-MM-dd`, disables transparency and animation effects, installs the elevated ReNeo logon launcher, installs portable AltSnap, and applies the user-profile application settings.

Sign out and sign in again after the first apply. The new sign-in applies the UI language and starts the ReNeo launcher. Enter the separate local `Administrator` credential at its prompt. If the current session must continue before that sign-out, select `Deutsch (Neo)` with `Win+Space` and start elevated ReNeo from standard PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File "$env:LOCALAPPDATA\WindowsConfiguration\start-reneo-elevated.ps1"
```

Enter the separate local `Administrator` credential. The same prompt appears at each later sign-in. One elevated ReNeo process supplies the missing higher layers to ordinary and elevated applications. The native driver supplies only the base layout on UAC's secure desktop.

Open 64-bit Windows PowerShell with **Run as administrator** again. Set `$zenPolicies` and apply only the Zen policy file:

```powershell
$zenPolicies = 'C:\Temp\windows-configuration\apply-zen-policies.ps1'
powershell -NoProfile -ExecutionPolicy Bypass -File $zenPolicies
```

Run all three tests again from the standard session, then reapply each artifact in the same context as before. The WinGet test must report that the system is in the described state. The keyboard and policy tests must report `kbdneo: desired` and `Zen policies: desired`. The second apply of every artifact must report no change.

DSC has no generation or transactional rollback. To change the declared state, review a repository revision and reapply its document and scripts. An interrupted apply can leave earlier resources changed, and reverting the artifacts does not uninstall an application unless the declaration explicitly requests its absence.

PowerToys is one monolithic package. Its other utilities remain installed, but the declaration enables only Command Palette. Portable AltSnap owns modifier dragging and 50/50 edge or corner snapping. The PowerToys parent is the only Command Palette startup owner; leave the separate startup task disabled.

The installation-scope audit has three Windows packaging exceptions. Windows Terminal has a per-user AppX registration, but Windows keeps its immutable package payload under `C:\Program Files\WindowsApps`. PowerToys keeps its payload and mutable files under `%LOCALAPPDATA%`, but its bundle also creates a hidden machine-wide MSI registration. Neither resource needs an elevated DSC token. Zen has a machine-wide application payload and policy file. The native Neo driver has checksum-pinned DLLs under `System32` and `SysWOW64` and one keyboard-layout registration under `HKLM`.

### Keep the unsupported surface manual

Use **Settings > Apps > Default apps** for file associations. Windows protects each current-user choice with a generated `UserChoice` hash. The document does not synthesize that unsupported value. The accepted manual bindings are:

| Application   | Extensions                                                                                                                            |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| Zed           | `.nix`, `.md`, `.json`, `.yaml`, `.yml`, `.toml`, `.sh`, `.ps1`, `.py`, `.js`, `.ts`, `.tsx`, `.rs`, `.go`, `.diff`, `.patch`, `.txt` |
| Adobe Acrobat | `.pdf`                                                                                                                                |

Keep the LaTeX previewer decision in the future `evaluate-pdf-toolset` change. Do not bind it in this workstation change.

Keep taskbar pins in user control. The supported taskbar-layout mechanism is a deployment policy, not a current-user convergence interface; using it here would replace or control the user's pin list. The document changes only taskbar visibility.

Keep **Country or region** set to Austria. The installed Widgets build uses that region to select German Microsoft-hosted cards and taskbar-weather text, even though the Widgets interface follows the `en-GB` culture. It exposes no separate content-language control. Accept that content language instead of changing regional Microsoft services.

Configure Night Light manually under **Settings > System > Display > Night light**. The accepted state is enabled from sunset to sunrise at 50% strength. Windows stores this state in an undocumented CloudStore binary payload, so the document does not write it.

### Verify the Windows roles

In Zed, run `projects: open wsl` from the command palette. Select `NixOS`, then open `/home/user/src/github.com/glockyco/nix-config`. Do not open the `\\wsl.localhost\NixOS\...` path as a local Windows folder. A local folder gives Linux ACP agents a Windows UNC working directory.

After the new sign-in, confirm these behaviors:

- Windows and PowerToys use English, and the taskbar date uses `yyyy-MM-dd`. Weather text remains German because the Austrian region controls Microsoft-hosted widget content.
- `Deutsch (Neo)` remains the default input method. Its base layer works in ordinary applications, elevated applications, and UAC. The elevated ReNeo process supplies higher layers in ordinary and elevated applications. UAC remains base-layer-only.
- PowerToys Command Palette launches an application and switches to an existing window. No other PowerToys module is enabled.
- AltSnap modifier-drag moves a window and snaps it to a 50/50 edge or corner region.
- Zed opens the NixOS worktree through its WSL transport and starts `nixd` and the wrapped `omp acp` command inside NixOS without SSH.
- Fork opens the same worktree through the pinned `wslgit` bridge. The accepted median `git status` time is 409 ms, compared with 723 ms for Windows Git over the UNC path and 4.3 ms inside NixOS.
- Zen renders the pinned Catppuccin Mocha theme with Mauve accents.
- Windows Terminal starts the NixOS default profile in the Linux home directory. JetBrainsMonoNL NF renders Powerline and device glyphs without a font warning.

## 13. Update the locked environment

Review and fast-forward the clone, then activate again:

```sh
cd "$HOME/src/github.com/glockyco/nix-config"
git pull --ff-only
sudo nixos-rebuild switch --flake .#korolev
```

The command does not update `flake.lock`.

## Rollback

### Windows layer

WinGet Configuration and DSC have no generation or transactional rollback. Stop after a failed resource, inspect its reported error and the state already applied, then revise and reapply the reviewed artifact. A repository revert changes the next desired state; it does not automatically uninstall applications or restore previous files. Use the NixOS rollback procedures below only for Linux state.

### Generation rollback

Read the retained generations, then restore the previous one:

```sh
sudo nixos-rebuild list-generations | cat
sudo nixos-rebuild switch --rollback --no-reexec
```

`--no-reexec` is required on this host. Without it, `nixos-rebuild` rebuilds itself from `<nixpkgs/nixos>` and fails with `error: file 'nixos-config' was not found in the Nix search path`, because `--rollback` accepts no flake reference.

Select a specific generation through the system profile:

```sh
sudo nix-env -p /nix/var/nix/profiles/system --switch-generation <number>
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
```

Both paths restore the system scope and the user scope together, and neither registers a new generation.

### Failed activation

A failed activation script registers its generation and leaves `/run/current-system` unchanged, so the previous closure keeps running. A measured probe reported `Failed to run activate script`, returned exit status 2, registered the new generation, and left no failed unit.

Roll back, then delete the rejected generation:

```sh
sudo nix-env -p /nix/var/nix/profiles/system --delete-generations <number>
```

### Distribution rollback

The previous distribution stays registered until every acceptance gate passes. Rollback before its removal is a distribution switch:

```powershell
wsl --terminate NixOS
wsl --distribution Ubuntu-26.04
```

Rollback after its removal uses a retained NixOS generation.

### OMP-owned state

Generation rollback changes the immutable wrapper, plugin, Herdr, OpenSpec, and language-server paths. It does not change the user-local OMP executable or OMP-owned runtime state. Use the explicit tagged installer command in step 7 to change the OMP version.

For a mutation audit, stop other OMP sessions and capture type, mode, owner, and inode before and after the change:

```sh
stat -c '%n type=%F mode=%A owner=%U:%G inode=%i' \
  "$HOME/.omp/agent" \
  "$HOME/.omp/agent/config.yml" \
  "$HOME/.omp/agent/agent.db" \
  "$HOME/.omp/agent/history.db"
```

Every inode must survive the change. A normal OMP session still changes database sizes and times.

## Failure recovery

Inspect before you make another change:

```sh
sudo nixos-rebuild list-generations | cat
systemctl --failed --no-legend --plain | cat
systemctl is-active user@1000.service
ls -la "$HOME/.omp/agent/extensions"
```

Do not delete `~/.omp`, edit `/etc/nixos`, or run `nix flake update` as recovery. Herdr alone owns `~/.omp/agent/extensions/herdr-omp-agent-state.ts`.

## Release evidence

Record these values for the accepted revision:

```powershell
$terminal = Get-AppxPackage Microsoft.WindowsTerminal
"windows-terminal=$($terminal.Version)"
cmd /c ver
wsl --version
```

```sh
. /etc/os-release
printf 'nixos=%s\n' "$PRETTY_NAME"
printf 'nixos-build=%s\n' "$BUILD_ID"
printf 'architecture=%s\n' "$(uname -m)"
printf 'kernel=%s\n' "$(uname -r)"
printf 'nix=%s\n' "$(nix --version)"
printf 'omp=%s\n' "$(omp --version)"
printf 'openspec=%s\n' "$(openspec --version)"
printf 'configuration-revision=%s\n' "$(nixos-version --configuration-revision)"
```

### Accepted evidence: 2026-09-03

| Item                    | Accepted value                      |
| ----------------------- | ----------------------------------- |
| Windows Terminal        | `1.24.11911.0`                      |
| Windows                 | `10.0.26100.9168`                   |
| WSL                     | `2.7.12.0`                          |
| WSL kernel              | `6.18.33.2-microsoft-standard-WSL2` |
| WSLg                    | `1.0.73.2`                          |
| Distribution            | `NixOS 26.05 (Yarara)`              |
| NixOS build             | `26.05.20260814.02e0898`            |
| Architecture            | `x86_64`                            |
| Nix                     | `2.34.8`                            |
| OMP                     | `18.0.10`                           |
| OpenSpec                | `1.11.0`                            |
| Implementation revision | `e4ec92b2c3c2`                      |
| System generation       | `7`                                 |

`nixos-version --configuration-revision` reports the revision of each generation, and the recorded revision is the one the Linux gates ran on. The imported host activated the reviewed revision, and a second activation of the same clean revision registered no further generation. An unprivileged build reached `cache.numtide.com` with no ignored-setting warning. Both providers answered a real request through fresh subscription logins. A real wrapped session in a disposable repository loaded the plugin from `/nix/store`, quoted the personal commit policy, completed a `personal_commit` preview, and left the repository unchanged. A deliberately failing generation kept the previous generation selectable, and the rollback preserved every OMP-owned inode. A container image ran through the `docker` command name and exited with its own status.
