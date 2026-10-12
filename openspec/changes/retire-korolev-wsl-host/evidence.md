# Implementation evidence: retire-korolev-wsl-host

## Reviewed scope (2026-10-12)

This records the owner-assisted native migration, not completed WSL retirement. Migration preceded the C3 archive at the owner's request. Docker was installed after the clones. Builder removal, export and unregister still wait for their gates. Nothing was published on the owner's behalf during project transfer.

## Task 1.3: owner decisions

Approved booking identifiers are private repository `glockyco/omp-booking`, marketplace `glockyco-booking` and plugin `booking`. The private export location is `C:\Users\jglock\Backups\wsl\`, retained for three months of native use and then deleted. The export will contain SSH/GPG keys, the pass store and omp logins. It must remain private and local. `/tmp/haroon/LLMCodeImpact`, with two local edits, stays only in the export. `/tmp/nix-shell.5eWt9a/dataset-packaging-*` is a dropped disposable agent fixture. Reference clones and smoke repositories are not migrated.

## Task 1.6: Docker installation and readiness

Owner-approved chezmoi apply used PR [#79](https://github.com/glockyco/nix-config/pull/79) head `959517d`, later merged as `eaa535a`. The owner supplied the machine-installer UAC credential. Apply exited 0 and `chezmoi verify --exclude=scripts` exited 0 for 61 units. Installer arguments were `install --quiet --backend=wsl-2 --no-windows-containers`, without automatic agreement acceptance or an always-running service.

The owner launched Docker Desktop as `jglock` and accepted the subscription agreement. Engine 29.8.2 linux/amd64, context `desktop-linux`, Compose v5.5.1 and the running `docker-desktop` distribution were observed. No `docker-users` membership was needed. `docker run --rm hello-world` passed. A Compose service mounted a path containing a space read-only and printed its marker. Smoke containers, network and images were removed. Fresh shells receive `C:\Program Files\Docker\Docker\resources\bin` from machine PATH.

## Tasks 2.1 and 2.2: inventory and preservation

The [runbook checklist](../../../docs/operations/korolev-windows.md#owner-assisted-project-migration) includes every root and nested relationship. The owner chose as-is preservation of unpushed commits, local branches, stashes, uncommitted, untracked and ignored data. Dated warnings were replaced by the observed inventory below, not a presumed clean state.

| Native path below `C:\Users\jglock\src`                   | Preserved state                                                                                                                                                                                                                                                             |
| --------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `github.com\glockyco\omp-agent-setup`                     | `main`. Three patch-equivalent merged branches skipped.                                                                                                                                                                                                                     |
| `github.com\glockyco\phd-thesis`                          | `main`, two unpublished commits `4f0697b`, `511bc22`. Five initialized `projects/` submodules at recorded commits. 51 ignored files, 9.6 MB.                                                                                                                                |
| `github.com\glockyco\test-generalization`                 | Origin `glockyco/Teralizer`, clean `master`. `jpf-symbc` and `projects/EqBench` stay uninitialized.                                                                                                                                                                         |
| `github.com\glockyco\Teralizer-Paper`                     | Local `revise-for-resubmission` and `macbook-pro` SSH remote retained. Merged `main` skipped. `correspondence` on `main`.                                                                                                                                                   |
| `gitlab.scch.at\foci\aisys\andritz\anita`                 | `research` ahead 1, behind 1. Local `catalog-analysis-simple`, `data-analysis`, `rebuild-catalog-analysis`. Stash "On rebuild-catalog-analysis: paused overbuilt phase-7 drafts". One modified notebook, two untracked files, nine ignored files, 48.6 MB, and LFS objects. |
| `gitlab.scch.at\foci\aisys\andritz\aqua`                  | `main`, ten untracked files under `docs/how-we-built-it.md` and `presentation/`. 18,517 ignored files, 774 MB, including evaluation runs, reports and cache. 113 regenerable cache symlinks skipped.                                                                        |
| `gitlab.scch.at\foci\aisys\saner2027-paper`               | `main`, Overleaf `paper` submodule and `github` mirror retained. Earlier five unpushed commits were on origin at refresh. 167 ignored files, 4.77 GB, mostly `output/`.                                                                                                     |
| `gitlab.scch.at\foci\aisys\saner2027-overleaf`            | Clean `main`, fast-forwarded 121 commits on refresh.                                                                                                                                                                                                                        |
| `gitlab.scch.at\scch\internal-tools\not-so-personalwolke` | `main`, local-only `nix-dev-shell`, untracked `book-project-hours/{SKILL.md,evidence.py}` retained. `.direnv` excluded.                                                                                                                                                     |
| `github.com\glockyco\nix-config`                          | Existing native checkout reconciled. Every WSL branch was on origin or patch-equivalent. No transfer needed. Stale WSL worktree in `%TEMP%\nix-config-feedback` removed.                                                                                                    |

## Task 2.3: source sessions closed

All WSL sessions ended with `/exit`: nix-config `01a1163b`, saner2027-paper `01a10fee` and `01a11bd9`, aqua `01a11fa3` and `01a11fd6`, not-so-personalwolke `01a11f35`, and Teralizer-Paper `01a10b24` from `/tmp`. Native aqua session `01a12f6f`, using the UNC WSL checkout, also ended. Transcripts remain in WSL `~/.omp/agent/sessions` for the retained export and were not imported.

## Task 2.4: as-is transfer without publication

For each repository and initialized submodule, temporary `refs/migrate/head`, `refs/migrate/worktree` from `git stash create`, and `refs/migrate/stash/N` captured HEAD, index/worktree and every stash without changing source work. Bundles included kept branches, tags, remote-tracking and temporary refs. Temporary source refs were then deleted. Only branches proven patch-equivalent by `git cherry` against origin's matching or default branch were skipped. The checked-out branch was always kept.

Recorded HEAD, branch/remote configuration, porcelain status, a fixed-option binary diff checksum, stash list and `.git/info/exclude`. Pax tars preserved untracked and ignored files, excluding platform environments (`.venv`, `node_modules`, `__pycache__`, `.direnv`, `.pytest_cache`, `.mypy_cache`, `.ruff_cache`), symlinks and Windows-invalid names. Local LFS objects had a separate tar. Only three `:Zone.Identifier` download markers were skipped as invalid names.

Native repositories used `git init`, LFS restoration, `git fetch <bundle> '+refs/*:refs/*'`, recreated remotes and upstream configuration, restored HEAD, `GIT_LFS_SKIP_SMUDGE=1` with `git reset --hard`, then `git lfs checkout`. Stashes were restored with `git stash store`, worktree/index with `git stash apply --index refs/migrate/worktree`, and file tars extracted. Initialized nested repositories used HTTPS `git submodule init` and `git submodule absorbgitdirs`. Uninitialized submodules stayed uninitialized.

Every repository and submodule compared with zero differences in ref names/SHAs, HEAD, porcelain status after documented exclusions, binary diff checksum, stash list and copied file counts/bytes. The retained WSL source remains a second copy until export. The owner publishes pending work when ready.

## Tasks 2.5 and 2.6: native HTTPS checkouts and credentials

All inventory roots are stable native ghq-layout checkouts. Origin URLs were mapped to HTTPS, other remotes retained, and `git fetch --prune` refreshed HTTPS remotes after transfer verification. `macbook-pro` is intentionally skipped until native SSH to the Mac exists.

GitHub used owner-confirmed `gh auth login --web --git-protocol https` and `gh auth git-credential`. GitLab used a new legacy token named "Korolev Git Credential Manager", with only `read_repository` and `write_repository`, expiring 2027-10-11. The owner used their logged-in Brave relay session, then the token went directly to GCM via `git credential approve`. Fine-grained Git/LFS coverage was uncertain, so it was not used. Overleaf used a newly generated Git token in GCM with username `git`. Token pages were closed. No credentials came from WSL and none were printed. Non-interactive `git ls-remote` with `GCM_INTERACTIVE=never` passed for all four SCCH repositories and the Overleaf project.

## Task 2.7: excluded content

Owner decisions cover `/tmp/haroon/LLMCodeImpact` and the disposable dataset fixture as recorded under task 1.3. `backnotprop/plannotator`, `can1357/oh-my-pi*`, dropped `/tmp` content and `/tmp` smoke repositories were not migrated.

## Tasks 3.1, 3.2 and 3.3: bounded decision banks

The runbook permits only `architecture.md`, `product.md` and `style.md`. Bank identity is `<basename>-<Bun.hash(cwd).toString(36)>` using the cwd omp actually sees. The algorithm matched three existing native banks, including UNC and space-containing paths, and the planned saner example.

| WSL bank                             | Native bank                         |
| ------------------------------------ | ----------------------------------- |
| `saner2027-paper-168zanlieu4n9`      | `saner2027-paper-3cdx7sc59ezhj`     |
| `anita-w6s13r5namow`                 | `anita-1jiaz86s8dvqy`               |
| `aqua-8z37opsbfmxa`                  | `aqua-2iufzybt9pvso`                |
| `not-so-personalwolke-3vup5j9gg48y1` | `not-so-personalwolke-qxhgi2qkna03` |
| `nix-config-2ugume9us7kzn`           | `nix-config-3uiai6lj0akn`           |

Copied files were byte-identical. The native UNC aqua bank `aqua-t47fhcxrpbx2` was empty, so no merge was needed. No queues, `state.json`, transcripts or databases were copied. Fresh native print-mode sessions in saner2027-paper and nix-config quoted a ported decision verbatim.

## Task 3.4: provider login pending

Native `%USERPROFILE%\.omp\agent\models.yml` reproduces the nonsecret WSL `providers.litellm.baseUrl: https://vllm-api.scch.at/v1` definition exactly. WSL's file has no key. The endpoint returns 401 without a key. The one stored WSL litellm credential was not copied. Owner-native `/login` and one real response remain pending. Task 3.4 is not complete.

## Tasks 3.5 and 3.6: booking plugin

Private [glockyco/omp-booking](https://github.com/glockyco/omp-booking), commit `14a7b5d`, publishes `booking@glockyco-booking` 0.1.0. CI passed on Windows, macOS and Linux with Python 3.13. The untracked source skill was preserved, not added to personalwolke as a shortcut. Concrete install/upgrade commands are in the runbook.

Fresh native RPC `get_available_commands` registered `skill:book-project-hours`. Its evidence helper ran natively for 2026-10-09, including retained WSL root `\\wsl.localhost\NixOS\home\user\.omp\agent\sessions`. The helper honors `PI_CODING_AGENT_DIR`, defaults to the native agent directory and accepts repeated `--session-root`. Start a fresh omp after install/upgrade. Open owner decisions concern Cumulix, the Teralizer comment prefix and a possible ten-hour daily maximum. No real booking acceptance is claimed.

## Task 3.7: native runtime ownership

Korolev uses the sole Tern-managed `%LOCALAPPDATA%\Tern\omp\bin\omp.exe`, with manager-installed `personal@glockyco` 0.4.0 and `booking@glockyco-booking` 0.1.0. Fresh native sessions and booking RPC discovery passed. No official-installer copy was added. These observed plugin versions are evidence, not permanent pins.

## Tasks 2.8 and 8.3: partial project acceptance

| Project              | Observed native acceptance and remaining gate                                                                                                                                                                                                                                                                                                                |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| phd-thesis           | [PR #4](https://github.com/glockyco/phd-thesis/pull/4) merged 2026-10-12. `latexmk main.tex` produced 230 pages with LuaLaTeX/biber. Pre-commit passed, strict OpenSpec passed seven changes, wrapper tests passed 13 with two POSIX-only skips. Local patch-equivalent `3a87b2f` sits beside two unpublished commits and is dropped by `git pull --rebase`. |
| Teralizer-Paper      | latexmk produced 58 pages. Strict OpenSpec passed. No changes.                                                                                                                                                                                                                                                                                               |
| omp-agent-setup      | Frozen Bun install, lefthook install and Python 3.13 venv with pywinpty 3.0.5. `bun run check:local` passed 156 tests.                                                                                                                                                                                                                                       |
| anita                | `uv sync` passed with CPython 3.14.8. Catalog notebook executed via nbconvert into ignored output. Owner state unchanged.                                                                                                                                                                                                                                    |
| aqua                 | Local-only `korolev-native`, `e7755ff`, portable locking/paths/test fixes and tracing budget. 845 tests, ruff and ty passed. Owner untracked files preserved. Compose gate pending.                                                                                                                                                                          |
| saner2027-paper      | Local-only `korolev-native`, `0b26b43`, spawn and lazy debugger imports. 732 passed, two skipped. Anonymous and camera-ready PDFs built. `S:` unmapped, UNC output share reachable. Container replication pending.                                                                                                                                           |
| saner2027-overleaf   | latexmk produced 12 pages.                                                                                                                                                                                                                                                                                                                                   |
| test-generalization  | Docker toolchain and materialized-symlink acceptance pending.                                                                                                                                                                                                                                                                                                |
| not-so-personalwolke | Compose acceptance pending.                                                                                                                                                                                                                                                                                                                                  |

Personal-project Mac-plus-Windows acceptance and remaining container gates are not fully proved here. Tasks 2.8, 3.4 and groups 4 through 8 remain incomplete, except for the separately verified task 4.2 below. No export or unregister success is claimed.

## Task 4.2: portable OpenSpec CI

The reviewed v0.4.0 annotated tag resolves to commit `aa97a3febee50f00ee7e4e43a81edc211ad7f8d7`. Its reusable workflow exposes only the optional repository-relative `openspec-root` input. nix-config supplies `'.'` and passes no CLI version, flags or archived opt-out.

[PR #82](https://github.com/glockyco/nix-config/pull/82), [OpenSpec job](https://github.com/glockyco/nix-config/actions/runs/38265496562/job/114866498796), checked out nix-config's caller merge revision `34fd0d3fec92446cc03b3cda14d5c00f867acfd4`, including head `2c49147f223ee71656910bf0b8918503d1bfd743`. The runner installed the workflow-owned `@fission-ai/openspec@1.14.0` in scratch. Strict noninteractive all-contract validation passed 25 items. Strict noninteractive archived validation passed 45 items. The job passed in 9 seconds.

Local fixtures executed the released workflow's exact gate script. A CLI double without `--archived` failed with the declared unsupported-archive diagnostic. Nonzero all-contract and archived validation each failed the gate. The successful fixture recorded exactly `validate --help`, `validate --all --strict --no-interactive` and `validate --archived --strict --no-interactive`. All fixture scratch directories were removed.

Task 4.7 remains unchecked. `personal-omp-plugin`, `openspecContracts` and `openspecAdapters` remain in the flake and lock. This CI addition does not claim local-hook cutover or authorize their removal.
