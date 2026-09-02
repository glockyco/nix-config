# Bootstrap personal OMP on WSL 2

## Scope

This procedure installs the locked personal OMP environment on an `x86_64` Windows work machine. Windows owns Windows Terminal, WSL enablement, and employer policy. Ubuntu owns the Linux user, Nix profile, Git configuration, repositories, and mutable OMP state.

The repository does not install Windows applications, approve external providers, copy credentials from another host, or manage project toolchains.

## 1. Prepare Windows Terminal and WSL

Install or update Windows Terminal Stable through the Microsoft-supported or employer-managed channel. In Administrator PowerShell, run:

```powershell
wsl --install --distribution Ubuntu-26.04
```

Restart Windows if requested. Create the Linux user when Ubuntu starts. Do not reuse a private SSH key or copy `~/.omp` from another machine.

In Windows Terminal Settings, make the generated Ubuntu profile the default. Set its command line to the generated `wsl.exe --distribution-id {...}` command with `--cd ~` appended. Keep the starting-directory field empty and retain the default terminal keybindings.

Close every Windows Terminal window, reopen it, and verify the Linux home directory:

```sh
test "$PWD" = "$HOME" && printf '%s\n' 'home-start=ok'
uname -m
```

The results must be `home-start=ok` and `x86_64`.

## 2. Install Linux prerequisites

Run in Ubuntu:

```sh
sudo apt-get update
sudo apt-get upgrade --yes
sudo apt-get install --yes git curl ca-certificates xz-utils openssh-client
```

Verify that PID 1 is `systemd`:

```sh
ps -p 1 -o comm=
```

Stop if the result is not `systemd`.

## 3. Install Determinate Nix

Run the official installer:

```sh
curl --proto '=https' --tlsv1.2 --silent --show-error --fail --location \
  https://install.determinate.systems/nix |
  sh -s -- install linux --no-confirm
```

Close every Windows Terminal window. Open PowerShell and run:

```powershell
wsl --shutdown
```

Reopen Ubuntu and verify Nix:

```sh
nix --version
nix store info
nix flake --help >/dev/null && printf '%s\n' 'flakes=ok'
```

## 4. Create a machine-specific GitHub SSH key

Create a new key. Replace `korolev` only when the machine has a different stable name:

```sh
ssh-keygen -t ed25519 -a 100 -C "korolev"
cat "$HOME/.ssh/id_ed25519.pub"
```

Set a passphrase. Add only the `.pub` value to GitHub as an authentication key. Verify access:

```sh
ssh -T git@github.com
```

GitHub must report successful authentication. It also reports that it does not provide shell access; that result is expected.

## 5. Clone and configure the repository

Keep repositories on the Linux filesystem:

```sh
mkdir -p "$HOME/src"
git clone git@github.com:glockyco/nix-config.git "$HOME/src/nix-config"
cd "$HOME/src/nix-config"
```

Set the work identity as the WSL default:

```sh
git config --global user.name "Johann Glock"
git config --global user.email "johann.glock@scch.at"
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global push.autoSetupRemote true
git config --global core.autocrlf input
```

The bootstrap sets only this checkout's email to `11704293+glockyco@users.noreply.github.com`. It does not replace the global work email.

## 6. Review and run the bootstrap

The root flake publishes these additional signed cache settings:

```text
extra-substituters = https://cache.numtide.com
extra-trusted-public-keys = niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=
```

They supplement the default NixOS and Determinate caches. Nix can ask whether to trust each setting on first evaluation. Compare the prompt with the values above before accepting it. Do not add the cache by editing `/etc/nix/nix.conf` or `/etc/nix/nix.custom.conf`.

From the repository root, run:

```sh
nix run .#bootstrap-omp-on-wsl
```

The command must stop before profile mutation unless the host is WSL 2 on `x86_64`. On success it:

1. sets the repository-local GitHub no-reply email;
1. installs or replaces one `personal-omp-wsl` user-profile entry;
1. creates `~/.omp/agent` only when Herdr needs that parent directory;
1. lets Herdr create or update its generated extension;
1. verifies the immutable plugin and current Herdr integration.

Expected final output includes:

```text
bootstrap-omp-on-wsl: ready
Git email: 11704293+glockyco@users.noreply.github.com
```

Verify the installed environment:

```sh
command -v omp
command -v openspec
command -v reconcile-herdr-omp
command -v verify-personal-omp
omp --version
openspec --version
verify-personal-omp
git config --local user.email
git config --global user.email
```

The local email must be the GitHub no-reply address. The global email must remain `johann.glock@scch.at`.

## 7. Authenticate providers

Start OMP and use its interactive model and provider selection:

```sh
omp
```

Complete fresh OpenAI and Anthropic logins. Do not copy authentication databases or tokens from another host. Confirm each provider with one real model response.

## 8. Run the real-session smoke

Create a disposable repository and start the installed wrapper:

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

The plugin path must be under `/nix/store`. The policy and `personal_commit` tool must be active. After leaving OMP, verify that preview created no state:

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

## 9. Update the locked environment

Review and fast-forward the repository, then rerun the same bootstrap:

```sh
cd "$HOME/src/nix-config"
git pull --ff-only
nix run .#bootstrap-omp-on-wsl
```

The command does not update `flake.lock` or any unrelated profile entry. Re-entry at the same revision does not add another profile entry.

## Failure recovery

A platform or repository preflight failure leaves the Nix profile unchanged. A reconciliation or verification failure after replacement rolls back to the previous profile generation and verifies the restored personal OMP environment. A failed clean installation removes the new profile entry.

The command preserves OMP-owned state. If Herdr created a mutable extension before a later failure, the command reports its path for inspection and does not delete it.

If automatic profile recovery fails, inspect before making another change:

```sh
nix profile list
nix profile history
ls -la "$HOME/.omp/agent/extensions"
```

Do not delete `~/.omp`, replace the whole Nix profile, use priority flags, or run `nix flake update` as recovery.

## Release evidence

Record these values for the accepted revision:

```powershell
$terminal = Get-AppxPackage Microsoft.WindowsTerminal
"windows-terminal=$($terminal.Version)"
"windows=$([System.Environment]::OSVersion.Version)"
wsl --version
```

```sh
. /etc/os-release
printf 'distribution=%s\n' "$PRETTY_NAME"
printf 'architecture=%s\n' "$(uname -m)"
printf 'kernel=%s\n' "$(uname -r)"
printf 'nix=%s\n' "$(nix --version)"
printf 'omp=%s\n' "$(omp --version)"
printf 'openspec=%s\n' "$(openspec --version)"
printf 'repository-revision=%s\n' "$(git -C "$HOME/src/nix-config" rev-parse HEAD)"
```
