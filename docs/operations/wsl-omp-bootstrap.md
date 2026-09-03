# Provision the korolev NixOS WSL host

## Scope

This procedure makes an `x86_64` Windows work machine run the NixOS host `korolev` under WSL 2. Three layers own separate state.

| Layer                | Owns                                                                                   |
| -------------------- | -------------------------------------------------------------------------------------- |
| Windows              | Windows Terminal, WSL enablement, employer policy, native applications, and the editor |
| NixOS host `korolev` | the Linux system scope, the user scope, and every executable path                      |
| OMP                  | authentication, configuration, sessions, history, caches, logs, and databases          |

Repositories stay under the Linux home directory, not under `/mnt/c`.

This procedure does not install Windows applications, approve external providers, copy credentials from another host, or manage project toolchains.

Standard Windows user rights are sufficient. The operator holds durable credentials for the local `Administrator` account. The declarative layer deliberately does not use them: distribution import, activation, generation rollback, and distribution rollback all run as the standard user.

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

## 7. Activate the host

Activate from a committed tree:

```sh
sudo nixos-rebuild switch --flake .#korolev
```

Read the output. The Home Manager activation runs Herdr reconciliation and then local verification, and the verifier prints the OMP version, the immutable plugin path, and `omp: current`.

Confirm the result:

```sh
sudo nixos-rebuild list-generations | cat
nixos-version --configuration-revision
systemctl is-system-running
systemctl --failed --no-legend --plain | cat
herdr integration status
```

The system must report `running` with no failed unit. A dirty worktree marks the generation revision with a `-dirty` suffix, and each edit produces another closure. A second activation of the same clean revision registers no second generation.

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

## 11. Set the Windows Terminal profile

Windows Terminal enumerates WSL distributions when its process starts, so a distribution imported later is absent from a running window. Close every Windows Terminal window and start Terminal again. The `Microsoft.WSL` generator then adds a `NixOS` profile with its own GUID.

Set that GUID as `defaultProfile`, and set the profile's starting directory to the Linux home directory. Keep the default terminal keybindings.

## 12. Update the locked environment

Review and fast-forward the clone, then activate again:

```sh
cd "$HOME/src/github.com/glockyco/nix-config"
git pull --ff-only
sudo nixos-rebuild switch --flake .#korolev
```

The command does not update `flake.lock`.

## Rollback

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

Rollback changes immutable wrapper, plugin, OMP, and language-server paths. It does not roll back, copy, or delete OMP-owned authentication, preferences, sessions, history, caches, or databases.

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
| Implementation revision | pending the final release gates     |

The imported host activated the reviewed revision, and a second activation of the same clean revision registered no further generation. An unprivileged build reached `cache.numtide.com` with no ignored-setting warning. Both providers answered a real request through fresh subscription logins. A real wrapped session in a disposable repository loaded the plugin from `/nix/store`, quoted the personal commit policy, completed a `personal_commit` preview, and left the repository unchanged. A deliberately failing generation kept the previous generation selectable, and the rollback preserved every OMP-owned inode. A container image ran through the `docker` command name and exited with its own status.
