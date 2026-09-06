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

## Release smoke

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

Nix rollback preserves the platform-owned OMP executable and writable OMP state.
Use the platform installer to recover an earlier release, then repeat [Release smoke](#release-smoke).
Do not delete `~/.omp` or copy credentials, databases, or browser profiles from another host.

On Darwin, Homebrew's [`version-install`](https://docs.brew.sh/Manpage) extracts a release from the [official tap](https://github.com/can1357/homebrew-tap).
Replace `<version>` with the release number without a leading `v`:

```sh
brew unlink can1357/tap/omp
brew version-install can1357/tap/omp <version>
brew link --overwrite --force "omp@<version>"
verify-personal-omp
```

On WSL, use the explicit release tag at the wrapper's fixed target:

```sh
curl -fsSL https://omp.sh/install \
  | PI_INSTALL_DIR="$HOME/.local/lib/oh-my-pi" sh -s -- --binary --ref v<version>
verify-personal-omp
```

## Desktop OpenSSH maintenance

The personal desktop uses the standalone Win32-OpenSSH ZIP distribution, not the Windows `OpenSSH.Server` capability or an MSI installation. Windows Update and ESU no longer service this SSH server. Review its version manually against [upstream releases](https://github.com/PowerShell/Win32-OpenSSH/releases); the accepted release and verification results are in the [desktop change evidence](../../openspec/changes/enable-native-windows-remote-work/evidence.md). Do not add an updater or execute Windows installers from Nix activation.

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
