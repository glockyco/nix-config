# Design

## Context

See `proposal.md` for motivation. The Mac's ordinary CLI inventory is `modules/shared/user-packages.nix`, imported into user packages by `modules/shared/user-environment.nix`. The Mac already has a separate Bitwarden desktop cask in `home/.chezmoidata/hosts.toml`. Neither it nor the browser extension supplies the intended platform-owned CLI contract.

Korolev installs applications from `windows/workstation.json`. `windows/Workstation.Validation.ps1` requires every declared role to have one stable application owner, so adding an inventory entry alone would fail validation. Existing WinGet entries use standard-user scope and present policy unless a concrete consumer requires a pin.

The README leaves credentials and sessions to applications. `user-configuration` preserves this boundary and the existing Mac-only age credentials. `personal-omp-workstation` prohibits managing OMP runtime state through workstation activation. OMP obfuscation settings and custom secret definitions therefore remain explicit per-host operator actions, never Nix or chezmoi declarations.

The existing `darwin-dependency-builds` contract and `packages/check-darwin-build-plans/package.nix` reject specific source-built toolchains and language servers. That guard does not independently establish that a new Bitwarden package is cached. Bitwarden therefore needs its own cache availability acceptance check as well as the existing guard.

The upstream [Bitwarden CLI guide](https://bitwarden.com/help/cli/) documents separate accounts through `BITWARDENCLI_APPDATA_DIR`, interactive authentication, `BW_SESSION`, and locking at the end of use. Its native downloads are x64, so the Apple Silicon installation must use the nixpkgs package rather than introduce an upstream binary download or npm-global install.

OMP's `omp://secrets.md` defines provider-bound obfuscation, reversible tool-argument restoration and plaintext restoration for local display and resume. It is disabled by default. At startup it collects values of at least eight characters from variables whose names contain `KEY`, `SECRET`, `TOKEN`, `PASSWORD`, `PASS`, `AUTH`, `CREDENTIAL`, `PRIVATE` or `OAUTH`, plus global/project secret definitions. Built-in shape rules can also recognize values later. Enabling obfuscation mid-session does not establish that an environment value was registered at startup.

The operator's Korolev observations on 2026-10-30 are input evidence, not checks rerun by this proposal: with obfuscation enabled mid-session, a fake Bearer header became a placeholder, but a fake 26-character `sk-...` key and a fake `BW_SESSION` assignment with an 88-character base64 value did not. Tern's `%LOCALAPPDATA%\Tern\daemon.state` contained tool output. These observations rule out relying on built-ins for the SCCH key or session and on provider obfuscation to protect local state.

## Goals / Non-Goals

### Goals

- Keep package installation declarative while server selection, account authentication and vault state remain application-owned.
- Default to granting only the task's named values, with the vault locked before the agent starts.
- Preserve an explicit secondary flow for unknown-upfront items without suggesting that startup registration covers values fetched later.
- Separate provider-bound protection, consumer non-disclosure and local-state exposure, and verify each flow with a canary before real use.

### Non-Goals

- A secret broker, sandbox, policy-enforcing wrapper, managed plugin or automatic unlock service.
- Migrating age credentials, vault contents, existing sessions or application state between hosts.
- Installing another desktop app or extension on Korolev, or changing the Mac's existing ones.
- Automatically editing ANITA or any other project to adopt Bitwarden.

## Decisions

### 1. Use existing platform package inventories

Add nixpkgs `bitwarden-cli` to `modules/shared/user-packages.nix`. This is the existing ordinary user-package owner, so a new role or overlay would add no useful boundary. Keep the desktop cask unchanged. The version follows the flake lock instead of a second pin.

Add a WinGet application to `windows/workstation.json` with name `package bitwarden cli`, kind `winget`, identifier `Bitwarden.CLI`, role `vault-cli`, scope `user` and version policy `present`. Register that stable role-to-identifier mapping in `windows/Workstation.Validation.ps1` and cover it in the existing validation tests. Do not duplicate a mutable version in checks or add an updater.

Use the existing engine's package discovery and executable resolution. Confirm the selected WinGet installer exposes `bw` in a fresh shell without elevation. Add declaration-level executable metadata only if the existing portable-package path mechanism needs it, using the actual manifest layout rather than assuming a WinGet Links directory. Do not add application-specific engine behavior.

On an actual `aarch64-darwin` host, evaluate `bitwarden-cli` from the flake's locked root nixpkgs input and inspect its closure against the configured substituters with an empty-store or equivalent cache query. Confirm that Bitwarden and its dependencies need no source build. A warm local store alone is not evidence of cache availability. Then run the repository build-plan guard and normal system build. If the locked selection is unavailable from cache, stop acceptance and resolve the package selection through review rather than silently compile it or change package managers.

### 2. Select persistent per-account directories explicitly

Use these application-owned directories:

| Host    | SCCH profile                                       | Private profile                                       |
| ------- | -------------------------------------------------- | ----------------------------------------------------- |
| Mac     | `~/Library/Application Support/Bitwarden CLI/scch` | `~/Library/Application Support/Bitwarden CLI/private` |
| Korolev | `%LOCALAPPDATA%\Bitwarden CLI\scch`                | `%LOCALAPPDATA%\Bitwarden CLI\private`                |

The operator creates private directories and selects one through process-local `BITWARDENCLI_APPDATA_DIR`. They are not in a repository, a synced configuration source or a temporary directory. On the Mac, use current-account ownership and mode 0700. On Windows, retain a current-account private ACL with normal operating-system administrative access, not access for other ordinary accounts.

Initialize the SCCH server with `bw config server https://password.scch.at` in its selected directory before login. Initialize the private profile independently after confirming its server. The working assumption is Bitwarden US cloud at `https://vault.bitwarden.com`. An EU or other private server changes only that operator-supplied endpoint, not the design.

Do not declare either `data.json` or even its non-secret server key through chezmoi. Bitwarden stores application state together there, so making part of that file managed would blur ownership and risk credentials or sessions. The operator procedure owns the initialization command instead. Do not copy existing desktop, browser or CLI profiles between accounts or machines.

No shell helpers or wrappers are needed. Explicit native zsh and PowerShell procedure examples are enough to select profiles, capture values and perform cleanup. No shell profile or `home/` change is planned.

### 3. Enable OMP protection as an operator action

On each host, the human enables `secrets.enabled` through OMP's settings UI or its supported runtime configuration interface. A settings change can take effect during a session, but environment-derived registration still depends on the values present at session startup. Start a fresh OMP process for each handoff rather than assume an existing process notices newly exported variables.

Nix-config must not manage OMP `config.yml`, `~/.omp/agent/secrets.yml`, profile-specific equivalents or project `.omp/secrets.yml`. Global and project plain/regex definitions are available OMP features, not a second secret-delivery mechanism to add here. Plain definitions would persist values, and a broad session regex can mistake unrelated data for secrets. Document the setting as a prerequisite and verify it with a canary.

Obfuscation replaces supported provider-bound text with reversible placeholders such as `$$HASH$$`. Tool arguments restore the value before execution. This permits a model to refer to a placeholder without receiving its plaintext, but does not remove the need for non-echoing consumers.

### 4. Prefer pre-exported task values with no agent vault session

The human selects one profile in a private terminal, runs interactive `bw login` when needed and captures `bw unlock --raw` into a shell-local session without echoing it. Capture raw login output too when initial login returns a session. Check native failures before proceeding. Passwords and second factors are entered only at Bitwarden prompts, never passed through agent tools, arguments, password files, password environment variables or chat.

For known requirements, capture only the approved fields directly into named environment variables such as `VLLM_API_KEY`. Their names must match OMP's documented secret-name patterns and their values must meet the minimum length. Do not print the values. Run `bw lock` for the selected profile and remove `BW_SESSION` and any `BW_SESSION_TOKEN` alias before starting OMP from that shell. Failed retrieval or failed locking prevents startup. OMP receives the task values for startup registration, but no vault session and no capability to retrieve unrelated vault items.

The named variables remain credentials available to the agent process and descendants. They are not sandboxed or encrypted process memory. Keep exports local to a short-lived task shell, never a persistent user/machine environment setter, shell profile, `.envrc` or OMP configuration. At completion, remove task variables and end processes that inherited them. Vault locking does not revoke the already exported API credential.

This is the primary flow for the ANITA external vLLM key. It reduces access compared with handing the agent a whole-vault session and automatically registers the otherwise unrecognized key through `VLLM_API_KEY` at startup.

### 5. Reserve session handoff for on-demand retrieval

Use this only when required items are not known before startup. The human unlocks one profile privately and exports the identical value as both `BW_SESSION` and `BW_SESSION_TOKEN` before starting OMP with obfuscation enabled. `BW_SESSION` is required by `bw`, but its name matches none of OMP's documented patterns. The `TOKEN` alias registers the same value at startup so supported provider-bound occurrences are obfuscated regardless of which variable supplied it. Check equality privately without displaying either value.

Prefer this alias to a global regex. It registers the exact session value and avoids assuming a fixed length or matching 88-character `sha512-...==` integrity values in lockfiles. No custom regex or real-session output probe is needed. Test the alias registration with an inert, made-up session-shaped value in a separate canary-only OMP process. Never print a live session merely to prove registration.

The task inherits only the selected `BITWARDENCLI_APPDATA_DIR` and those session variables. Other vaults remain locked. The agent retrieves the smallest approved field, not full items or vault listings. A session grants reads of the entire accessible vault and may authorize writes. Neither an item identifier, collection filter nor profile directory makes it item-scoped. A dedicated Vaultwarden account with server-side access limited to an agent-usable organization or collection can reduce exposure if SCCH permits it. A collection under an otherwise broad account does not.

Fetched values are not automatically added to OMP's startup registry. Assigning a fetched value to `VLLM_API_KEY` in a child process does not register it in the existing OMP process. The reported SCCH key shape must be treated as unrecognized. Route such values directly into a non-echoing consumer. If a workflow needs to expose the value to model-visible text, return to human-controlled pre-export and a fresh startup rather than assume built-in coverage.

On success, failure or interruption, lock the selected profile, clear both session variables and derived secrets, and end inheriting processes. Use zsh traps or PowerShell `finally` in the procedure. A subsequent retrieval without a new session must fail noninteractively. Clear and lock before switching profiles.

### 6. Keep values inside the consumer flow

Both flows use process-local environment variables, stdin or an authorization header constructed inside the consuming process. Do not put secret literals in command arguments. For on-demand access, pipe `bw get` into the consumer within one tool call rather than capture raw retrieval as a tool result. Stop the consumer if retrieval fails. Output contains only non-sensitive status.

Do not use environment dumps, shell tracing, PowerShell transcription, verbose HTTP headers, `tee` or diagnostics that echo values. OMP obfuscation is a second layer for registered or recognized values, not authorization to log them. It does not cover every field or binary payload, static system prompts or static tool definitions, and it cannot protect an unregistered value with an unsupported shape.

If an approved project requires a local `.env` file, establish its ignore rule and private permissions before direct writing. Never print, stage or read it back through an agent tool. Explain its persistent plaintext trade-off and remove it when no longer needed. Process-local delivery remains the default.

### 7. Gate real use on per-flow canary checks

The human creates a throwaway item such as `omp canary` in each vault to be used. Its made-up, key-shaped value is at least eight characters and is first confirmed not to match a built-in pattern. No real item is retrieved until that flow passes on that host and vault. The canary is not a real credential, so controlled probes may expose it to distinguish actual obfuscation from a superficially successful consumer.

For the primary flow, pre-export the canary under the intended matching name, lock the vault, clear sessions and start OMP. A controlled canary-only output probe must appear to the agent as a placeholder, not plaintext. Exercise consuming a restored placeholder without printing the value. The agent reports the placeholder it sees, and the human compares that view with the canary they know. Local display of plaintext is not evidence that the provider saw plaintext, since OMP restores it for display.

For the on-demand flow, use a fresh process with the real session privately registered through its alias, but do not register the canary value. Pipe `bw get` directly into the exact proposed non-echoing consumer. Exercise both success and safe failure. At these output points the agent must see only status and no value, not claim a placeholder for data that never crossed the output boundary. Validate alias registration separately with the inert session-shaped fixture. Do not emit the live session.

Use an isolated canary-only output probe as a negative control for the unsupported fetched-key shape. If it appears as plaintext in the agent's view, that output path has leaked and cannot be used with real secrets. This does not approve the emitted value through post-hoc redaction. The constrained pipe flow passes only when its own normal and failure output contain no plaintext. Any workflow requiring a displayed value must instead pass startup registration in a fresh process. A Bearer-only positive control is insufficient because its shape can conceal a missing registration.

For every probe, the agent states placeholder, plaintext or no value at the tested location and the human confirms. Do not infer success solely from terminal display, a screenshot or a consumer exit code. Check the working tree, tracked files and commits for the canary without adding the canary itself to a scan command argument, report or committed fixture. Record only outcome and flow identity, never the canary value.

Delete the canary item after acceptance or rejection and clear its environments. Fresh canaries for later regression checks avoid stale values remaining registered and falsely making a broken handoff appear safe. Keep no permanent test item or plaintext fixture in the repository.

### 8. Explain local plaintext separately

Provider obfuscation is not local-storage encryption. OMP restores reversible placeholders for tool execution, local session display and resume, then re-obfuscates supported text for provider replay. Terminal scrollback and saved terminal state can also retain tool output. On Korolev, the reported Tern state location is `%LOCALAPPDATA%\\Tern\\daemon.state`.

During implementation, identify the actual OMP local session storage location for the active agent directory on each host and confirm persistence/display/resume behavior with the canary. Identify the Mac's Tern state location too. Do not guess a universal session path or copy local state into the repository. Inspect only canary-bearing records privately and record locations and outcomes, not real content.

The operation guide must warn that plaintext may persist locally even when the agent sees only placeholders. Apply the host's account permissions, disk protection and backup policy to that application-owned state. Do not have Nix or chezmoi reset, rewrite or purge it. Locking a vault or deleting a canary entry does not erase terminal records, OMP sessions, exported values or consumer files. Non-disclosure still depends on agent discipline and consumer behavior, especially for on-demand values.

### 9. Keep the procedure in the operations guides

Add `docs/operations/bitwarden.md` with native zsh and PowerShell flows for setup, operator-only OMP enablement, primary pre-export, secondary session aliasing, per-flow canary gates, non-echoing delivery, cleanup and local-state limits. Link to OMP's supported secret-obfuscation documentation for its source contract instead of inventing a Nix-owned setting.

Update the README Secrets section in place to distinguish Bitwarden access from unchanged Mac-only age credentials. Link from the Korolev guide's manual setup steps. Keep mutable inventory facts in declarations and put observations or measurements in this change record, not the operation guide. Do not edit `AGENTS.md` or personal-plugin instructions.

## Risks / Trade-offs

- Pre-exported secrets remain usable after vault locking. Mitigation: grant only required values to a short-lived process and end inheriting processes when the task finishes.
- On-demand sessions grant broad account access and fetched values may not be registered. Mitigation: make pre-export the default, register the exact session via its startup alias, pipe values without output and reject unsafe canary paths.
- Provider obfuscation can succeed while local state retains plaintext. Mitigation: verify both layers with canaries and document host-local locations, permissions, disk and backup protection without claiming runtime-state erasure.
- A generic built-in regex can make a weak test pass. Mitigation: use a fresh canary outside built-in shapes and test startup registration, restoration and the actual consumer's failure path separately.
- File delivery leaves plaintext on disk. Mitigation: prefer process-local delivery and establish ignore rules and private permissions before any required file write.
- A package cache miss can compile a large closure. Mitigation: require cache evidence separately from the forbidden-toolchain guard.
- Host validation needs interactive credentials and actual applications. Mitigation: keep operator-approved gates explicit and do not substitute static or mocked checks.

## Migration Plan

1. Add the platform declarations and validation coverage, then write and link the operator procedure. Existing age credentials and application profiles remain untouched.
1. Run the README checks for both platforms and strict OpenSpec validation. Run Nix commands serially on the Mac and record Bitwarden cache availability before activation.
1. Request an interactive Mac activation in the documented order, with the human entering any sudo password. Retain the previous generation and run ordinary-user chezmoi verification.
1. Request the operator's approval for the PR-branch engine dry run and `chezmoi apply` on Korolev. The operator runs both as the standard user and reviews named drift. Confirm convergence afterward. No unattended apply or Administrator script is added.
1. On both hosts, check `bw --version` in fresh native shells. Initialize isolated profiles and have the human enable OMP obfuscation. Run the primary and constrained on-demand canary gates for each vault used, including consumer failures, alias registration and local-state inspection. Delete canary entries afterward.
1. Only after the corresponding canary gate passes, use the approved ANITA external vLLM key through that flow and check a real consumer without displaying the key. Record only paths, versions, exit statuses and non-sensitive outcomes.
1. Do not accept or archive until package cache, live apply, profile isolation, both flow gates, local-state documentation and cleanup requirements pass. No runtime settings, canary creation or real retrieval occur during this proposal.

Rollback the Mac package change through a retained generation and user-file changes through their source revision. On Windows, revert the declaration and apply source changes, with package removal remaining an explicit operator action. Leave both vault profiles and OMP runtime state intact. Lock and end session-bearing processes separately, clear exported task credentials, and follow application-supported local-history handling if needed. Package rollback does not revoke already exported credentials or erase local state.

## Open Questions

- Confirm the private account's server during its interactive setup. US cloud is the planning assumption, not a managed endpoint.
- Which non-echoing consumer should exercise the ANITA external vLLM key after canary acceptance? The operator supplies its item identifier privately. The actual OMP session and Mac Tern state locations must be identified on the hosts during canary verification rather than guessed here.
