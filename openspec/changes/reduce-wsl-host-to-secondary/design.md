# Design

## Context

See `proposal.md` for motivation. This change is applied only after changes 1–3 are archived and native Windows Korolev has passed a real Tern/OMP session and a WSL-daemon remote Mac build. The planning checkout still contains Home Manager, the patched OMP wrapper, and WSL Tailscale; these are observed pre-migration facts, not implementation targets to restore.

Repository evidence read on 2026-10-07:

| Evidence                                                                                             | Consequence                                                                                                                                                                                                                                                |
| ---------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `modules/roles/nixos/wsl-workstation/default.nix:19-46`                                              | WSL declares the GPG agent, pinentry, Linux GCM/GnuPG/`pass`, `GPG_TTY`, GPG credential store, and Overleaf generic provider. Change 2 moves their packages/files to system-user packages/chezmoi; change 4 removes the resulting declarations.            |
| `programs.nix:34-69` in that role                                                                    | `nixd` is currently system-wide; the only foreign-binary-loader rationale names .NET, Unity, game loaders, and OMP Chromium. The owner says the first three workloads are Mac-only.                                                                        |
| `fonts.nix:4-10`, `flake-modules/checks.nix:123-131,157-160`, `checks/omp-browser-runtime-check.nix` | Fonts and the ABI check support Linux rendering. Searches across active modules, hosts, packages, checks, flake modules, and operations found no VHS package, tape, or other explicit font consumer; VHS appears only as an example in the font rationale. |
| WSL `containers.nix`, `wsl.nix`, `builders.nix`; `hosts/korolev/default.nix:15-48`                   | Rootless Podman/official Compose, supported `/init` interop, dedicated root builder credentials, and SCCH read-only automount are existing supported capabilities.                                                                                         |
| `packages/wsl-open/package.nix` and `tests.nix`                                                      | `open` translates paths and dispatches URIs to native Windows without browser fallback or command-interpreter indirection. Preserve these semantics and tests.                                                                                             |
| `openspec/changes/manage-wsl-git-credentials/*`                                                      | The unfinished plan assumes Windows Git is prohibited and requires a Linux credential store; the owner's verified per-user Windows Git ownership decision supersedes it.                                                                                   |
| `openspec/changes/mount-scch-share-on-wsl-host/{design,evidence,tasks}.md`                           | Reachable/read-only SCCH behavior has live evidence; its off-network repeated-failure gate is still unchecked. Do not absorb, delete, or claim completion of that independent change.                                                                      |
| README; `docs/operations/wsl-omp-bootstrap.md`; `docs/operations/container-runtime.md`               | Keep NixOS activation/recovery and the existing rootless Compose smoke; remove WSL browser/GPG procedures after native Windows guidance has taken ownership.                                                                                               |

External evidence:

- [Microsoft's WSL Git setup](https://learn.microsoft.com/en-us/windows/wsl/tutorials/wsl-git): install Git in each filesystem; invoke Windows GCM from WSL, store credentials in Windows Credential Manager, and configure GCM through Windows Git by default. GCM supports HTTPS, not SSH.
- [GCM's WSL instructions](https://github.com/git-ecosystem/git-credential-manager/blob/main/docs/wsl.md): configure the actual Windows `.exe` as WSL Git's helper; quote spaces; x64 Git ≤2.55 uses `mingw64/bin`, while ≥2.56 uses `ucrt64/bin`.
- Owner-approved fleet evidence: installed per-user Git 2.55.0.5 has `%LOCALAPPDATA%\Programs\Git\mingw64\bin\git-credential-manager.exe`. This is an observed path, not a permanent upstream layout guarantee. Change 3 owns its WinGet declaration and update lifecycle.

## Goals / Non-Goals

**Goals:** Preserve the remaining WSL workflows without duplicate file ownership, Windows credential storage in Linux, or a foreign-binary loader kept for abandoned workloads. Make the retained capabilities demonstrable on the activated host.

**Non-Goals:** Remove WSL, stop Linux OMP/editor use for this repository, strip unrelated CLI packages, change tailnet routes/identity, redesign SCCH or Podman, add a Linux browser fallback, delete GPG/browser/container data, or automate corporate/provider authentication. No implementation or live-state changes occur while authoring this plan.

## Decisions

### 1. Preserve a bounded secondary role and its existing owners

Keep the role directory/import identity rather than rename it and churn callers. NixOS retains system configuration, Nix and shell enablement, packages, rootless Podman, builder client settings, interop and the SCCH mount; chezmoi retains user shell/Git/CLI configuration from change 2. Shared facts remain in `home/.chezmoidata/*.toml`, with `hosts.korolev.platforms.linux/windows` data and `data.host = korolev` distinguished by `.chezmoi.os`.

Retain `nixd` exactly once in `users.users.${config.host.username}.packages`, removing its older `environment.systemPackages` entry if it survived prior migrations. Nix/OMP/editor work on this repository is a retained WSL use case; entering a dev shell is not required merely to resolve the language server. Keep the system/release helper `tailnet-builder-check` and the root-only key/pin. Do not undo the Windows-owned `korolev` tailnet identity/routing established and verified by change 3.

**Alternatives:** Remove Linux OMP/editor tooling entirely (contradicts retained repo work); leave `nixd` duplicated system-wide (needless ownership overlap); require every editor to enter a dev shell (changes supported discovery semantics).

### 2. Invoke the installed Windows GCM directly from WSL Git

Use the same chezmoi Git template established by change 2, branching for Korolev/Linux. It renders an empty `credential.helper` reset followed by one properly quoted, absolute WSL-translated path to the installed Windows GCM `.exe`. Record the installed helper's exact relative path in shared host data, derive Windows LocalAppData through supported Windows environment discovery during user setup/rendering, and use `wslpath` to translate it. Do not bake `C:\\Program Files` or a Windows account name into a Nix module. No shell wrapper, Linux helper fallback, credential copying, or `WSLENV` callback configuration is needed for the recommended Git-for-Windows mode.

Verify the actual file and version before rendering/applying. If a Git update moves `mingw64` to `ucrt64`, update the shared path and reapply chezmoi; do not silently search stale and new helpers at credential-request time. Windows Git's provider/proxy settings are authoritative for Windows GCM. The native Windows chezmoi Git config from change 3 must own Overleaf's generic-provider setting where that service is used; remove the Linux `credentialStore=gpg` and Linux provider setting, and document this boundary.

Remove WSL Linux GCM/GnuPG/`pass` packages, GPG agent/cache TTL and pinentry configuration, and `GPG_TTY` from the post-change-2 files. Remove WSL `gh` credential-helper overrides if they would bypass GCM for HTTPS; retain the HTTPS protocol preference, Git identities, and the separately mutable `gh` CLI login. SSH authentication is unchanged. For a consumer with a repository-local helper override, explicitly remove only that obsolete override with owner approval; activation never edits repository-local config.

**Alternatives:** Linux GCM plus GPG/`pass` (duplicate store and terminal unlock problem); plaintext Git `store` (unacceptable); machine-wide helper path (wrong for the verified install); relying on `gh auth setup-git` (does not prove Windows GCM); a new credential wrapper/discovery fallback (unneeded runtime indirection).

### 3. Retire WSL browser ABI, relay and unused font support

Remove the browser `programs.nix-ld` block entirely, its browser-runtime check file/registration, and browser ABI acceptance instructions. No other active declaration consumes `nix-ld`; the owner excludes the only named nonbrowser workloads from WSL. Windows GCM's Windows executable uses Windows' loader, not Linux `nix-ld`.

Remove `fonts.nix`, its role import, and the WSL font check, and remove the `Monospace font for Linux rendering` requirement. No retained repository-owned renderer justifies that closure; Tern renders on Windows with Windows-owned fonts. This does not prohibit a project from declaring VHS and its fonts in its own environment.

Remove the WSL browser-relay requirement/procedure. Native Windows browser automation is already accepted under changes 0/3, not a replacement relay hosted in WSL. Leave existing browser profiles/extensions/downloads untouched; no package/font cutover is permission to delete user state. Keep `open` and standard interop for local browser links, annotations where supported, and Windows GCM.

**Alternatives:** Keep `nix-ld` or fonts for hypothetical consumers (no remaining declared requirement); retain WSL relay as backup (violates clean cutover); uninstall native Brave/modify user profiles here (Windows/browser ownership is outside this change).

### 4. Separate requirement retirement from unrelated acceptance

The delta modifies only `Declarative WSL Windows interoperability`, removes the owned browser/relay/font requirements, and adds secondary-role and Windows-GCM behavior to `wsl-host`. Earlier changes own the rest of that capability. `container-runtime` and `cross-platform-open-command` contracts remain unchanged. Delete only the unarchived `manage-wsl-git-credentials` directory; its never-archived `wsl-git-credentials` capability requires no main-spec removal. Preserve historical archives and the unfinished SCCH change.

README/AGENTS.md describe native Windows as primary and WSL as secondary; existing operations files keep only WSL-specific import, checkout, NixOS-plus-chezmoi apply/recovery, GCM boundary, containers, SCCH and builder guidance. Link Windows-native setup rather than duplicate it. Do not edit earlier changes' already-migrated OMP/plugin procedures back to wrapper/updater conventions.

**Alternative:** Archive the obsolete GPG plan first (would accept and immediately remove an unverified contract); fold the SCCH change into this one (unrelated owner/work).

## Risks / Trade-offs

- [Git for Windows updates may change the helper path.] → Confirm the installed `.exe` and version, update shared path data explicitly, rerender, and repeat authenticated HTTPS smoke. A stale path is a visible failure, not reason for Linux fallback.
- [Windows GCM reads Windows Git config, and local/helper overrides can mask it.] → Inspect effective helper origins without printing credentials; keep provider/proxy settings in native Windows chezmoi files and use a private/authenticated remote, not a public `ls-remote`, to prove GCM.
- [Corporate/provider policy may prevent GUI login or Windows credential persistence.] → Owner performs interactive login/MFA; keep the previous system/user configuration until the no-prompt post-restart smoke passes. Do not bypass policy or claim acceptance from config checks alone.
- [Removing the loader/font could break an undeclared renderer.] → The repository/owner evidence supports removal; test actual retained repo workflows. Any newly demonstrated consumer requires an explicit requirement/design revision, not a hidden fallback.
- [WSL Mac routing depends on Windows Tailscale/DNS from change 3.] → Repeat root/Nix-daemon remote build after this switch; preserve the strict pin and builder key, and do not re-enroll WSL as a second `korolev` node.
- [SCCH disconnected behavior is not yet accepted by its own change.] → Preserve that change and record this change's reachable smoke separately; let its outstanding VPN failure gate finish under its own acceptance record.

## Migration Plan

1. Confirm prerequisite archives and native Windows session/builder evidence; record their accepted revisions. Confirm per-user Windows Git/GCM path and Windows provider config before deleting the Linux credential declarations.
1. Remove declarations/snippets/checks and the superseded in-flight credential directory; render chezmoi variants and check both Nix systems without touching live credentials. Compare the WSL closure and prove removed support is not explicitly retained.
1. Review the implementation and run ordered README Nix formatting/flake/host-build gates. Publication/merge needs explicit owner authorization. Keep previous NixOS generations and a recoverable chezmoi source revision, since Nix rollback alone no longer restores user files.
1. Activate committed Korolev with `sudo nixos-rebuild switch --flake .#korolev`, then user `chezmoi diff`/`chezmoi apply`/`chezmoi verify`. Agent runs sudo in a terminal; owner enters any password. No Windows Administrator action is expected here; any repair requiring UAC stays an explicitly owner-assisted change-3 operation.
1. In Tern run authenticated HTTPS Git with Windows GCM, including no-terminal-prompt reuse after WSL restart, then shell/CLI/`nixd`, Podman/Compose, SCCH, `open`, root Mac SSH status and a fresh Mac remote build. Because loader/package changes affect the Linux agent environment, repeat the upstream/plugin real-session smoke in a disposable WSL repository; no Linux browser smoke remains.
1. If rejected, select the retained NixOS generation using README rollback with `--no-reexec`, restore the prior chezmoi source revision and apply its WSL files, and repeat retained-workflow checks. Neither action rolls back Windows Credential Manager, Git for Windows, OMP, tailnet enrollment, nor user GPG/browser/container data. Retain old credential material without using it until the new store passes; deletion/revocation needs a separate owner decision.
1. Record verification evidence and archive only this change after every gate passes. Do not remove the previous generation before that point.
