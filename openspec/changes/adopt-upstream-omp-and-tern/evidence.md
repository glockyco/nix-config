# Evidence

All live checks ran on 2026-10-07 unless stated otherwise.

## Prerequisite release (task 1.1)

`publish-plugin-through-omp-plugin-manager` released `personal@glockyco` `0.2.0` from omp-agent-setup `3eead69` (tag `v0.2.0`). Its evidence records the published re-fetch into a disposable HOME, the six `personal:opsx-*` commands, nine skills, both extension modules and the LSP overrides.

## Before the cutover (tasks 1.2-1.7)

|                                 | Korolev WSL                                                                                        | macbook-pro                                                                       |
| ------------------------------- | -------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| `omp` before                    | Nix wrapper `/etc/profiles/per-user/user/bin/omp`                                                  | Nix wrapper `/etc/profiles/per-user/glockyco/bin/omp`                             |
| Source generations              | current `v18.6.1-qmbdlzi5`, previous `v18.4.1-7d1j1oy5` (3.7 GB)                                   | current `v18.6.1-cjm7ce18`, previous `v18.4.1-wmzn9koz`, plus three older (11 GB) |
| Last wrapper-era Nix generation | 51 (`92c0834`)                                                                                     | 129 (`4f0b915`)                                                                   |
| Official install                | `$HOME/.local/bin/omp`, `omp/18.8.0`, ELF x86_64 using `/lib64/ld-linux-x86-64.so.2` from `nix-ld` | `$HOME/.local/bin/omp`, `omp/18.8.0`, Mach-O arm64                                |

The installers were read before use: `install.sh` honours `--binary`, `--ref <ref>` and `PI_INSTALL_DIR` (default `$HOME/.local/bin`); `install.ps1` takes `-Binary`, `-Ref` and defaults to `%LOCALAPPDATA%\omp`, and writes `shellPath` to `~/.omp/agent/settings.json` only when none is set. The plugin was installed through each absolute official binary with `omp plugin marketplace add glockyco/omp-agent-setup` and `omp plugin install --scope user personal@glockyco`; `omp plugin list` showed one user-scope `personal@glockyco (0.2.0)` on each host. Before activation, a Korolev session of the official binary in the disposable repository `/tmp/omp-release-smoke` read `skill://commit-policy` and previewed a commit through `xd://personal_commit`.

## Implementation and release gates (tasks 2-5)

PR #62 merged by rebase as `c190a9d` (`feat(omp)!: use upstream OMP, the plugin manager, and Tern`) and `7d2be25` (`fix(omp): keep Ghostty and Herdr as secondary tools`). Required checks `check (macos-15)`, `check (ubuntu-latest)` and `test` passed. Before merge: `nix flake check` on Linux, the all-systems check, `nix run .#check-darwin-build-plans` (56 outputs) and `nix build .#darwinConfigurations.macbook-pro.system` on the Mac passed.

Activations, each from a committed revision:

| Host        | Generation | Revision  | Note                                           |
| ----------- | ---------- | --------- | ---------------------------------------------- |
| Korolev     | 52         | `abe6cc2` | first cutover, Ghostty/Herdr removed           |
| Korolev     | 53         | `5c2ff86` | Ghostty/Herdr kept as secondary tools          |
| Korolev     | 54         | `7d2be25` | reapply after the recovery gate, merged `main` |
| macbook-pro | 130        | `abe6cc2` | first cutover, owner typed the sudo password   |
| macbook-pro | 131        | `5c2ff86` | Ghostty/Herdr kept                             |

`systemctl is-active user@1000.service` was `active` and `sudo -n -l` reported `NOPASSWD` before each Korolev activation. The rollback and reapply output named no OMP or Herdr step.

Zed (task 3.3): only `agent_servers.omp` was removed from `%APPDATA%\Zed\settings.json` (command `omp`) and the Mac's `~/.config/zed/settings.json` (command `/etc/profiles/per-user/glockyco/bin/omp`); a JSON diff showed no other change.

## Real sessions (task 6.1)

Fresh login shells, after activation:

| Command                                                                                    | Korolev WSL                                                                                     | macbook-pro                                                     |
| ------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------- | --------------------------------------------------------------- |
| `omp`                                                                                      | `/home/user/.local/bin/omp` (`omp/18.8.0`)                                                      | `/Users/glockyco/.local/bin/omp` (`omp/18.8.0`)                 |
| `openspec`, `plannotator`, `herdr`                                                         | `/etc/profiles/per-user/user/bin/…` (1.14.0, 0.27.12)                                           | `/etc/profiles/per-user/glockyco/bin/…` (1.14.0, 0.27.12)       |
| markdown-oxide, nixd, pyright-langserver, svelteserver, texlab, typescript-language-server | profile                                                                                         | profile                                                         |
| `Microsoft.CodeAnalysis.LanguageServer`                                                    | absent                                                                                          | profile                                                         |
| `marksman`                                                                                 | absent                                                                                          | absent                                                          |
| `tern`                                                                                     | Tern for Windows 0.6.0 (`0e39682`)                                                              | `/Applications/Tern.app/Contents/MacOS/tern`, 0.6.0 (`0e39682`) |
| Plugin                                                                                     | `personal@glockyco (0.2.0) (user)`                                                              | `personal@glockyco (0.2.0) (user)`                              |
| Platform                                                                                   | x86_64, NixOS 26.05.20261002.774debe, WSL 2.7.12.0, kernel 6.18.33.2-2, Windows 10.0.26100.9448 | arm64, macOS 26.6.2                                             |

Tern: the Mac ran a disposable session in Tern 0.6.0 (`tern serve`/`tern ctl`), where `/personal` completion listed the six `personal:opsx-*` commands and `personal_commit` printed its preview verbatim. On Korolev the integrating session itself runs the official binary in Tern for Windows, and the owner's screenshot shows the same six commands.

RPC sessions in disposable Git repositories on both hosts: `/personal:opsx-explore …` arrived as the expanded command template and the agent ran `openspec list --json`; the release prompt read the commit policy from `~/.omp/plugins/cache/plugins/glockyco___personal___0.2.0`, read the writing skill's example index and previewed `chore: verify release smoke` verbatim. `git status --porcelain` stayed empty and no commit was created. Discovery reported both extension modules, nine skills, the policy, `xd://personal_commit` and each command once, with no extension errors.

## Language servers (task 6.3)

Real RPC sessions with fixtures at fixed roots, project dependencies installed in the fixture:

- Both hosts: Python (pyright 1.1.411), TypeScript and JavaScript (typescript-language-server 5.3.0), Svelte (0.17.31), Nix (nixd 2.9.1), Markdown (markdown-oxide 0.25.12) and LaTeX (texlab 5.25.1) each returned the deliberate diagnostic, a definition, references and an applied rename. Markdown Oxide reported the unresolved link and renamed `note.md` to `renamed-note.md` from a body symbol, updating the link.
- macbook-pro, real HotRepl clone: Roslyn 5.12.0-1.26426.8 returned CS0029, the definition, 24 references and a rename across 13 files; post-rename diagnostics and definition followed the new name. The first diagnostic during cold project load returned `Operation aborted`, while RPC `get_state` answered within 0.15 s.
- Korolev: with a root `.csproj`, C# reported `No language server found`; Roslyn and Marksman were never selected or resolved.

Two upstream behaviours, not configuration failures of this change:

- texlab starts only when the session root has `.latexmkrc`, `latexmkrc`, `.texlabroot`, `texlabroot` or `Tectonic.toml` (OMP's built-in definition).
- BibTeX citation navigation fails on both hosts: definition `No definition found`, references `No references found`, and rename `Applied rename:` without edits. OMP 18.8.0 opens `.bib` files with language ID `plaintext`, because its extension table maps only `tex` to `latex`. A direct texlab 5.25.1 client resolved `\cite{acceptance}` to `refs.bib` with two references when `refs.bib` was unopened or opened as `bibtex`, and found nothing when it was opened as `plaintext`. The retired wrapper's OMP had the same table.

## Browser (task 6.5)

In a fresh WSL session, OMP's managed headless Chromium opened `https://example.com/` with `relay: false`: title `Example Domain`, screenshot captured, tab released, no missing-library error. The page no longer has an `<h1>`, so the documented smoke now checks the title. The run was repeated after every old source-generation session had stopped, with the same result. In both runs the first `browser.open` attached to the browser relay because the owner's `~/.omp/agent/config.yml` sets `browser.relay: true`; the managed browser needs an explicit `relay: false`, which the documented prompt's "not the browser relay" leads the agent to pass.

Activation and rollback did not touch OMP's browser state: the newest entries under `~/.omp/puppeteer`, `~/.omp/browser-profiles` and `~/.omp/browser-relay` predate the recovery gate.

## Updates (task 6.6)

On both hosts `omp update` reported `Current version: 18.8.0`, `Already up to date`; `omp plugin marketplace update glockyco` and `omp plugin upgrade --scope user personal@glockyco` left `personal@glockyco` at `0.2.0`. 18.8.0 is upstream's latest release (published 2026-10-07). No new release was installed.

## Recovery (task 6.7)

Korolev: `sudo nixos-rebuild switch --rollback --no-reexec` moved generation 53 to 52, where a fresh login shell no longer found `herdr` and still resolved `omp` to `$HOME/.local/bin/omp`. Reapplying the merged revision produced generation 54 (`7d2be25`) with `herdr` back. Fingerprints of `~/.local/bin/omp`, `~/.omp/plugins/installed_plugins.json`, `~/.omp/plugins/omp-plugins.lock.json`, the plugin cache entry, `~/.omp/agent/{config,models}.yml`, the extension list (including the owner's `herdr-omp-agent-state.ts`) and the session directory count were identical before rollback, after rollback and after reapply.

Both hosts: `curl -fsSL https://omp.sh/install | HOME=<tmp>/home PI_INSTALL_DIR=<tmp>/bin sh -s -- --binary --ref v18.8.0` installed `omp/18.8.0`, byte-identical to the accepted `~/.local/bin/omp`, into the isolated directory, and was removed afterwards.

## Desktop (task 6.8)

Through `desktop-batch` (PowerShell 7.6.6, user `User`): `omp update` moved the standalone binary from 18.1.12 to 18.8.0 at `%LOCALAPPDATA%\omp\omp.exe`; OMP's shell is Git Bash (`C:\Program Files\Git\bin\bash.exe`). The marketplace commands installed `personal@glockyco` `0.2.0`. In disposable repositories under `%TEMP%`, with a space in the path: `/personal:opsx-explore` expanded and ran `openspec list --json` (OpenSpec 1.12.0 from Bun), and the release prompt read both skills from `C:\Users\User\.omp\plugins\cache\plugins\glockyco___personal___0.2.0\…` and previewed the commit verbatim; the repository stayed unchanged and the directories were removed. No SSH, network or language-server change was made.

## Owner checks in Tern for Windows (tasks 6.2, 6.4 on Korolev)

In a WSL tab of Tern for Windows 0.6.0, in the disposable repository `/tmp/acceptance gate`, the owner checked:

- Links (6.2): `https://example.com/` was clickable. Plain Linux paths, a path with `:12`, a path with spaces and `/mnt/s/Common` were not clickable. Tern for Windows does not detect Linux paths in WSL output; its log earlier showed file links from WSL sessions resolving as `C:\home\user\…`. No terminal flags or patches were added to change this.
- Image and redraw (6.2): the official `omp` displayed `gradient.png` inline, and the session redrew correctly while the window was resized narrow and wide.
- Plannotator (6.4): `/plannotator-annotate "notes with spaces.md"` opened the review in the Windows browser; one submitted comment reached the session once; `/plannotator-last` and `/plannotator-cancel` worked. Afterwards no Plannotator process or listener remained, and the repository was unchanged (`git status` empty, fixture commit unchanged).
