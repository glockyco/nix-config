# Dependency Updates

Use this runbook for release acceptance, OMP version recovery, or external authorization repair.
Routine [updates](../../README.md#update), [release gates](../../README.md#develop), [activation](../../README.md#activate), and [Nix rollback](../../README.md#recover) have one README owner.
Keep the previous Nix generation until activation verification and every required smoke pass.

## Ownership and release order

The README identifies automated owners and schedules. Neither updater merges pull requests.
The [central controller](https://github.com/glockyco/dependency-automation#operations) owns manual dispatch, run inspection, and [App key rotation](https://github.com/glockyco/dependency-automation#key-rotation).
Target repositories hold no App credential. Do not enable a second Nix updater or Renovate's Nix manager.

Use the existing [plugin release procedure](https://github.com/glockyco/omp-agent-setup#release-flow) and [Erenshor dependency procedure](https://github.com/glockyco/erenshor-data-mining#dependency-maintenance).
Publish a verified plugin revision before advancing `personal-omp-plugin` here. Do not install it through OMP's mutable plugin manager.
After an OpenSpec update, regenerate adapters in the plugin repository with `nix run .#sync-openspec-adapters` before advancing its pin here.

For an artifact update, change the version, platform asset selection, and fixed hash together.
Use the [Markdown Oxide](../../packages/markdown-oxide.nix) or [Roslyn](../../packages/roslyn-language-server.nix) declaration.
Never accept changed bytes under an existing hash.
If the plugin selects a different server, publish its verified revision and change the wrapper package selection together.
Do not publish a plugin that selects an unavailable server or retain the previous server as a fallback.

## Plannotator updates

The OMP wrapper uses the unmodified vendor package from the commit-qualified `plannotator-packages` input in [flake.nix](../../flake.nix). Plannotator advances only on request. Its vendor recipe and transitive inputs stay pinned while routine lock updates can advance other tools. Keep the vendor's own Nixpkgs selection; do not add a workstation `nixpkgs` follow.

For an explicit Plannotator update:

1. Review the selected vendor revision and its Plannotator version.

1. Change the full commit in `inputs.plannotator-packages.url` in `flake.nix`.

1. Update only its lock selection:

   ```sh
   nix flake update plannotator-packages
   ```

1. Review the declared URL and lock diff together.

1. Build the selected package on both supported systems and record its version and Nix output paths with the change.

1. Verify document and last-response feedback in the wrapped OMP session, without approval controls or source edits.

1. Verify explicit cancellation, then complete the existing host release and rollback gates before replacing the working generation.

There is no downstream Plannotator patch or custom CI cache. The configured vendor substituter and local Nix stores provide ordinary output reuse. Cache availability is not guaranteed. A changed package derivation can require a build even when the application version stays unchanged. Startup and activation do not prepare mutable Plannotator installations.

### Cancelling an annotation review

Closing the browser tab does not guarantee cancellation in the stock annotation-only CLI. A pending review can keep its local process running and prevent another review in that session. Other OMP work can continue.

Use `/plannotator-cancel` to cancel the pending review before starting another. The adapter also cancels reviews on session navigation and shutdown. Browser annotations provide feedback only; they do not edit the source or approve implementation.

## Agent-led OMP updates

The repository-local [omp-update skill](../../.agents/skills/omp-update/SKILL.md) guides an agent through this procedure.
Start a fresh wrapped OMP session in this checkout and request an update, or invoke `/skill:omp-update`.
The result is a verified selected runtime, not only a repaired patch series or instructions for unfinished work.

### Preflight and authorization

1. Identify the current host and system from the environment and repository declarations. Default to that supported host unless the user names another.
1. Resolve `omp`, `omp-dev-update`, and `verify-personal-omp` from the caller's command environment. Inspect their resolved launchers for ownership; do not select a convenient developer executable.
1. Read [the declared inputs](../../packages/omp-dev-update.nix). Resolve the installed updater script and read the immutable JSON path passed to its `--config` argument. Compare its upstream URL, fork URL, patch base, patch tip, and system with the reviewed repository declaration. Do not execute file contents to extract these fields.
1. Run `omp-dev-update --status` to record the selected release, upstream, patch range, resulting commit, and system. Inspect the declared state root's `current` and `previous` targets and their generation metadata. A first installation can have neither target. Status metadata describes the selected generation, not necessarily the installed updater's current pins.
1. Inspect repository changes and granted scope. Preserve unrelated work. A normal update request authorizes the existing updater's selection on the current host, unless restricted. Obtain missing authorization before patch publication, configuration publication, host activation, or recovery outside the granted scope. Never infer fleet permission from access to a remote builder.

If installed pins differ from the reviewed repository pins, establish which revision is intended before preparation.
If the intended pin change is already reviewed and committed, reuse that commit; do not edit or recommit identical pins.
A reviewed local commit can be activated without a nix-config push. Request configuration publication only when that operation is required by the user's scope.
Run the applicable [release gates](../../README.md#develop), review and commit the intended configuration, then perform authorized [activation](../../README.md#activate).
Do not activate unrelated or unreviewed changes. Read activation output and resolve the installed updater again before retrying.
Building a package does not install its pins. Publishing a fork branch does not activate either host.

If administrator interaction is unavailable, report the exact host command from the README and the current selection.
Do not ask for passwords or private-key contents. Resume after the operator provides the activation result.
If the host or command ownership is unsupported, report that prerequisite instead of installing another OMP distribution.

### Prepare and accept the runtime

1. If a failure was already reported, inspect its phase and candidate before another attempt. Do not rerun a known failure merely to confirm it.
1. Otherwise, run `omp-dev-update` through the installed command. It selects the latest stable upstream release using the installed pins.
1. If preparation succeeds, run `verify-personal-omp` and complete [Release smoke](#release-smoke) in a fresh wrapped session through Herdr. Include the WSL browser check when applicable.
1. If inputs are unchanged, verify the selected runtime and report **already current**. Do not manufacture a patch refresh, pin edit, or new generation.
1. If preparation fails, use the reported phase and candidate location to select the repair path below. A failed candidate need not have `generation.json`; that file is written after successful preparation.
1. If smoke fails after selection, report failed acceptance and follow authorized [OMP version recovery](#omp-version-recovery). Repeat verification after recovery. Do not report the recovered older release as a successful upgrade.

The updater owns its process lock, candidate worktree, retained development environment, verification phases, and atomic promotion.
Do not edit `current` or `previous`, remove a process-held lock, manually promote a candidate, or invent prepare-only or resume flags.
An interrupted or rejected preparation leaves the previous selection available; inspect the selection before reporting its state.
Retain previous generations while any session uses them.

### Repair a non-conflict failure

Read the reported command, exit status, phase, and relevant source before choosing a repair.
Use [the updater implementation](../../packages/omp-dev-update.py) as the current phase and command reference.

- **Fetch or input validation:** check declared URLs, release/tag identity, exact commit availability, ancestry, and existing credential access. Do not print tokens, change credential ownership, or accept a moving branch as a pin.
- **Environment or dependencies:** inspect the resolved release's Nix shell and lockfiles, available disk space, and the actual dependency error. Preserve frozen dependency installation; do not update locks merely to make installation pass.
- **Native build:** use the target host's development environment and native output. Do not copy another host's native artifacts or bypass the build with an executable fallback.
- **Package checks or regressions:** investigate the failing behavior. Keep failures visible and verify the source repair before retrying production preparation.
- **Native loading or CLI smoke:** inspect the native error, source launcher, immutable plugin input, and caller environment. Do not rewrite mutable OMP configuration or add a launcher fallback.
- **Lock or promotion:** inspect the owning operation and recorded state. Wait for legitimate work or report the failure; do not delete state to force another updater through.

Use a separate worktree for source repairs. Follow the same verification and publication boundaries as a patch refresh.
If a repair requires an updater contract change, use a separately reviewed OpenSpec change rather than silently expanding the current update.
Retry only after a diagnosed cause or prerequisite has changed. State any remaining blocker and preserve the failed candidate for inspection.

### Refresh the maintained patches

1. Record the failing range and resolved stable upstream commit from installed inputs, updater output, and Git state. Inspect the candidate read-only, including its conflict blocks and relevant upstream changes. Do not repair the failed candidate in place.
1. Use a separate maintained Git repository or worktree outside the updater's active generations. If none exists, create an owned temporary clone from the declared sources. Fetch the exact old base and tip plus the resolved stable release; verify commit identities, ancestry, and the release tag as the updater does.
1. Create a new versioned maintenance branch at the old patch tip. Rebase that range onto the resolved upstream commit using `git rebase --onto <upstream-commit> <old-base>`. Resolve each overlap by understanding both behaviors, not with a blanket ours/theirs strategy. Preserve the original branch.
1. Review `git range-diff <old-base>..<old-tip> <new-base>..<new-tip>` and the complete diff from the new upstream base. Check every intended fix, unintended changes, and release notes. Move personal notes to the appropriate unreleased section without rewriting published upstream entries.
1. If upstream now supplies a fix, verify its behavior before retiring the redundant patch. Do not silently preserve or discard a patch based only on whether Git applies it. The updater rejects an empty or merged patch range; if no patches remain, report the need for a reviewed updater contract change. Do not create a dummy patch to pass validation.
1. Verify the refreshed source before publication. Read the current `PHASES`, `REGRESSIONS`, and `prepare` implementation in the updater, then execute the corresponding checks in the resolved upstream development environment. Preserve its frozen dependency installation, host-native build, package checks, behavior regressions, native loading, and immutable-plugin launcher checks. Check the relevant upstream scripts if their interfaces changed.
1. Use isolated application state for verification: separate HOME, XDG directories, OMP/PI agent paths, and an outside-checkout launch directory. Remove inherited runtime overrides as the updater does. Keep the personal plugin at its declared immutable path. Do not copy authentication databases or run aggregate setup commands that install global links.
1. Request any missing permission to publish the concrete new branch to the declared fork. Publish only the verified commits, without force-pushing or rewriting the original branch. Verify the exact base and tip can be fetched and their ancestry checked independently on both supported hosts. Missing host access is a verification blocker, not permission to copy a checkout or claim that check passed.
1. Update the exact `patchBase` and `patchTip` in the repository declaration. Record verification with the relevant change and use the personal commit policy for task-owned changes. A patch-fork push does not authorize a nix-config push. Keep semantic updater changes in their own reviewed change.
1. Complete the applicable README gates, review and merge the intended configuration, and perform authorized activation on the requested host. Inspect activation output and confirm the installed inputs. Then rerun `omp-dev-update` and complete runtime acceptance; do not stop at publication or pin integration.

A newer stable release can appear during maintenance. Record the release actually selected on retry and verify that result.
If replay fails against that newer release, inspect the new failure; do not claim that earlier verification covered it.
Only the updater prepares and selects the production generation. Verification worktrees are not alternate runtime installations.

### Completion and handoff

Report **updated**, **already current**, **recovered**, or **blocked**, with the observed host and selected identities.
Include the verifier result, fresh-session smoke, immutable plugin path, Herdr status, and previous-generation availability.
Name the commits, publications, and activations actually performed, and distinguish any existing session still using an older generation.
If no previous generation exists, report that limitation; never invent a successful rollback.
For blockers, name the failed phase, candidate if present, current selection, missing prerequisite, and exact next operator action.
Keep evidence with the change or session, not as historical release facts in this manual or skill.

## Release smoke

### Herdr prerequisite

Before controlling panes, check `HERDR_ENV` with `printenv HERDR_ENV` through the Bash tool that will execute Herdr.
Eval's environment can differ from the command environment; a missing Eval value alone does not establish a Herdr blocker.

- If Bash reports `1`, read `herdr --skill` and follow its control policy for the fresh wrapped-session smoke.
- If the marker is absent or not `1`, do not control the user's Herdr session or set the marker yourself. Complete independent checks, including the managed-browser smoke when available. Report the fresh Herdr-session checks as blocked and request that the operator resume them from a Herdr-managed OMP session.
- If the command check fails for another reason, report that error rather than interpreting it as an absent marker.

Herdr availability does not establish permission to control unrelated panes. A missing marker does not establish that OMP's managed browser is unavailable.

### Runtime checks

After activation or an OMP executable change, run `verify-personal-omp`.
It must report the observed OMP version, a plugin path under `/nix/store`, and `omp: current`.
For an `llm-agents`, plugin, wrapper, extension, or OMP executable change, start a fresh wrapped `omp` session in a disposable repository.
Ask it to report the loaded `@glockyco/personal-omp-plugin` source path and quote the personal commit policy.
Then request a `personal_commit` preview with these fields:

```text
action=preview
subject="chore: verify release smoke"
body="The release must prove that the immutable personal commit extension loads without changing repository state."
repo="."
```

The plugin path must be under `/nix/store`, the policy must apply, and preview must leave the repository unchanged.
A workflow-only or documentation-only change needs no model-backed smoke. It still needs every [release gate](../../README.md#develop).
On WSL, repeat the [managed-browser smoke](wsl-omp-bootstrap.md#managed-browser-smoke) after OMP updates, recovery, or browser ABI changes.

For language-server changes, use fresh wrapped sessions at fixed representative project roots on both supported systems.
OMP discovers root markers in its working directory, not child directories.
Supply project SDKs through each project's development environment. A server runtime does not supply the C# SDK.
Require diagnostics for every supported language, plus definition, references, and rename where supported.

For Markdown Oxide, require an unresolved-link diagnostic, a resolved link's definition, and its references.
Rename a note from its body, then verify the filename and referring links.
A rename at a link or heading selects a different target.

For Roslyn, keep OMP responsive during project loading. Record early results separately from authoritative post-load results.
After loading, require a compiler diagnostic, definition, references, and a rename that changes the declaration and its usage.
A missing server, unsupported operation, crash, lost edit, or persistent semantic failure fails acceptance.
Record initialization and post-rename diagnostic failures separately. Successful retries do not erase them.
Do not add sleeps, hidden retries, or timeout overrides to manufacture acceptance.

## OMP version recovery

Nix rollback preserves the selected OMP source generation and writable application state.
On macbook-pro and korolev, select the previous verified generation without a download or rebuild:

```sh
omp-dev-update --rollback
verify-personal-omp
```

Rollback fails without changing the selection when no previous generation exists. Repeat [Release smoke](#release-smoke) afterward.
Do not delete retained generation directories while sessions use them, delete `~/.omp`, or copy credentials and databases from another host.

An update failure leaves the current generation selected and reports the failed phase and candidate location. Resolve patch conflicts in the maintained Git series, publish only with explicit authorization, and review its pinned input here before retrying. Do not edit an active generation or use the official installer as a fallback.

## Desktop OpenSSH maintenance

The personal desktop uses the standalone Win32-OpenSSH ZIP distribution, not the Windows `OpenSSH.Server` capability or an MSI installation. Windows Update and ESU no longer service this SSH server. Review its version manually against [upstream releases](https://github.com/PowerShell/Win32-OpenSSH/releases); the accepted release and verification results are in the [desktop change evidence](../../openspec/changes/archive/2026-09-06-enable-native-windows-remote-work/evidence.md). Do not add an updater or execute Windows installers from Nix activation.

Perform service changes at the Windows console in an administrator PowerShell session. The selected SSH account also has enabled administrator privileges, but stopping its transport is not a safe way to run its installer. Keep the console available and preserve repositories, agent state, host keys, and labelled authorization entries.

Before an update:

1. Identify the service binaries and package owner. Do not mix the Windows capability, MSI, and ZIP installation methods.
1. Retain the accepted ZIP and back up `C:\ProgramData\ssh`, including file ACLs, in a local directory restricted to Administrators and SYSTEM. Record service startup settings and effective firewall rules. Do not export private keys to another host or repository.
1. Select an exact release. Check the ZIP's SHA-256 against GitHub's release digest, then verify valid Microsoft Authenticode signatures on its executables, DLLs, and PowerShell scripts. Review preview status explicitly.
1. Test the candidate with the existing host key and authentication policy before replacing services. Do not accept a handshake alone as proof of command or SFTP compatibility.

Follow the [upstream ZIP installation procedure](https://github.com/PowerShell/Win32-OpenSSH/wiki/Install-Win32-OpenSSH). For an existing ZIP installation, its signed `uninstall-sshd.ps1` stops and removes both `sshd` and `ssh-agent`. Confirm that both service registrations are gone before installing the selected package; do not repeat `install-sshd.ps1` against a service pending deletion. Close service-management handles if Windows reports pending deletion, and coordinate a restart if Windows requires one. Keep the old package directory until acceptance passes.

Install the verified package at `C:\Program Files\OpenSSH`, with write access restricted to Administrators and SYSTEM. From the local administrator session:

```powershell
$ErrorActionPreference = 'Stop'
& 'C:\Program Files\OpenSSH\install-sshd.ps1'
Get-Service sshd, ssh-agent | Set-Service -StartupType Automatic
Start-Service sshd, ssh-agent
```

Do not enable the broad `OpenSSH SSH Server (sshd)` firewall rule. The reviewed preview MSI also adds an unrestricted TCP/22 exception; do not substitute it for the ZIP procedure. Preserve the existing tailnet-destination rules, public-key-only authentication, PowerShell default shell, and SFTP subsystem. Check the active server binary independently of `ssh.exe` on `PATH`; client and server versions can differ.

After installation, use the Pro's pinned `desktop-batch` endpoint to verify the negotiated key exchange, unchanged host identity, native command status, a spaced-path SFTP round trip, and rejection of an unapproved key and mismatched host pin. Verify both services' startup state and effective firewall rules. Keep the client cryptography warning enabled.

To recover from a failed ZIP update, use the local console and the same supported remove/install procedure with the retained accepted package. Restore the saved SSH configuration and ACLs if they changed, restore startup settings, and repeat transport acceptance. Removing the Windows capability can remove its server binary: pointing the service back to `C:\Windows\System32\OpenSSH\sshd.exe` is not a recovery procedure when that file is absent. Returning to capability ownership requires an explicit Windows capability installation, not an executable fallback. Do not reinstall or restart the working server merely to rehearse this procedure.

The desktop's agent stack is manual too, and separate from this repository's wrapper. OMP is the standalone Windows executable under `%LOCALAPPDATA%\omp`, installed with the official installer at a pinned tag and checked against the release digest; do not install it through Bun, which produces a shim this fleet rejects. The personal plugin is a source checkout at the revision this repository pins, loaded with `--plugin-dir` and `--extension`; update it explicitly rather than by automatic pull. Language servers are deliberately absent there. Record any accepted version change with its digest in the owning change.

### Sources, revocation and session lifetime

Each source holds its own key and its own labelled line in `C:\ProgramData\ssh\administrators_authorized_keys`. Enrolled sources are `air`, `pro-enclave`, `pro-yubikey` and `korolev`. Revoke exactly one source by deleting its line, then confirm that source is refused with `Permission denied (publickey)` while the others still authenticate. Keep the file's ACLs granting only `SYSTEM` and `Administrators`; anything wider makes `sshd` refuse every key without a useful error. Add a key only through the desktop's own session, after checking the candidate's fingerprint.

Place any `sshd_config` edit in the global section deliberately. Appending puts the directive after the `Match Group administrators` block, where it applies only to that match, and `sshd -t` accepts the file anyway.

Agent work uses non-interactive commands, `ssh desktop-batch '<command>'`. An agent ends with its SSH connection: no multiplexer is installed and no process survives a dropped client, so resume saved conversation state explicitly rather than expecting a live session. A graphical connection is different: the desktop keeps one session per user with no disconnection timeout, so RDP takes over the signed-in console session and retains its work after disconnecting.

Unattended access also depends on coordination-server state. Keep the desktop's Tailscale key expiry disabled and check it from Windows:

```powershell
(tailscale status --json | ConvertFrom-Json).Self |
  Select-Object DNSName, Online, KeyExpiry
```

Require the intended desktop identity, `Online: true`, and `KeyExpiry: null`. This setting is not part of the repository's rendered tailnet policy. A tagged node cannot receive Taildrop; use authenticated SFTP. A reboot test requires an owner-coordinated true restart; verify that the services return automatically. The desktop starts into a signed-in session, so pre-sign-in access is not a state it reaches. Never weaken `LimitBlankPasswordUse` or store a logon password in the registry to keep an automatic sign-on; account credentials are the owner's operation.

## Tailnet authorization recovery

Use this procedure when policy federation fails or its trust configuration changes.
Access to both GitHub repository settings and the Tailscale administration console is required.
The [workflow declaration](../../.github/workflows/tailnet-policy.yml) owns job inputs and deployment conditions, not provider authorization.

Configure separate validation and deployment identities with issuer `https://token.actions.githubusercontent.com`, separate generated audiences, and the shared `TS_TAILNET` value:

| Identity      | GitHub secrets                         | Exact Tailscale scopes                                                     |
| ------------- | -------------------------------------- | -------------------------------------------------------------------------- |
| PR validation | `TS_TEST_OAUTH_ID`, `TS_TEST_AUDIENCE` | `policy_file:read`, `devices:posture_attributes:read`, `devices:core:read` |
| Deployment    | `TS_OAUTH_ID`, `TS_AUDIENCE`           | `policy_file`, `devices:posture_attributes`, `devices:core:read`           |

Read-only validation exposes policy and device information. Public error logs can expose account details.
OIDC issuance alone grants no Tailscale API permission. The provider must enforce this scope separation.

Inspect the repository's subject configuration and immutable identifiers:

```sh
gh api repos/glockyco/nix-config/actions/oidc/customization/sub
gh api repos/glockyco/nix-config --jq '{id, created_at, owner_id: .owner.id}'
```

Compare each live job's actual subject and claims with the saved provider trust.
Do not assume legacy subject strings: GitHub supports immutable-ID subjects and custom templates.
Apply these restrictions with each identity's exact actual `sub`:

| Claim          | PR validation           | Deployment                                                                 |
| -------------- | ----------------------- | -------------------------------------------------------------------------- |
| `repository`   | `glockyco/nix-config`   | `glockyco/nix-config`                                                      |
| `event_name`   | `pull_request`          | `workflow_run`                                                             |
| `base_ref`     | `main`                  | Not applicable                                                             |
| `ref`          | Not constrained to main | `refs/heads/main`                                                          |
| `workflow_ref` | Not constrained to main | `glockyco/nix-config/.github/workflows/tailnet-policy.yml@refs/heads/main` |

Add `repository_id` and `repository_owner_id` from repository metadata where supported.
Use `workflow_ref`, not `job_workflow_ref`: these jobs do not use a reusable workflow.
Never permit a repository-wide wildcard deployment subject. A new GitHub environment requires a coordinated subject update.
Record only selected claims, scopes, issuer, and audience associations. Never log or persist bearer tokens or secret values.
Reopen the saved provider settings and compare them before acceptance.

For a fork PR without secrets, import reviewed changes onto a repository branch for authenticated validation.
Do not skip the required check or use `pull_request_target` to give PR-controlled code deployment authorization.

Before accepting repaired authorization:

1. Run real PR validation with the read-only identity and both native matrix checks.
1. Confirm that the validation token cannot write policy and that deployment rejects the PR token.
1. After review and merge, confirm successful native main checks followed by apply of their exact checked SHA.
1. Confirm that the live policy equals that SHA's rendered policy.
1. Confirm that failed checks and PR completions cannot deploy, and obsolete revisions cannot replace current policy.

Keep GitHub's supported queued concurrency setting even if a pinned local validator does not recognize it.
Require actual GitHub acceptance rather than filtering errors or weakening serialization.
GitHub and Tailscale share no transaction: main can advance after the freshness check, before the provider write.
An active checked apply can finish before a newer checked apply. Queue overflow and manual cancellation can omit intermediate revisions.

Treat console policy edits as emergency actions. Reconcile them through a reviewed PR, because the next GitOps apply replaces them.
See the provider's [scopes](https://tailscale.com/docs/reference/trust-credentials#scopes), [federation](https://tailscale.com/docs/features/workload-identity-federation), and [GitOps](https://tailscale.com/docs/integrations/github/gitops) documentation.
