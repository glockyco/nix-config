# Spec Delta

## Purpose

Provide native Bitwarden CLI access on both workstations with isolated accounts, least-privilege task secrets and verified protection against provider-bound disclosure, without claiming protection for local terminal or session state.

## ADDED Requirements

### Requirement: Native Bitwarden CLI on both workstations

A fresh shell on macbook-pro and native Windows Korolev SHALL resolve `bw` from its platform-owned installation. Mac delivery SHALL use a cached package rather than compile Bitwarden or its dependencies from source. Korolev installation SHALL use standard-user scope without elevation and SHALL preserve an already installed newer version.

#### Scenario: Resolve the command after installation

- **WHEN** the reviewed configuration has been activated on the Mac and applied on Korolev
- **THEN** `bw --version` succeeds in a fresh Mac zsh and a fresh native PowerShell 7 session
- **AND** no competing installer, Linux launcher or Administrator prompt is needed for Bitwarden CLI

#### Scenario: Inspect Mac package delivery

- **WHEN** the Mac installation is accepted against the pinned package selection
- **THEN** Bitwarden CLI and its dependency closure are available from the configured binary caches
- **AND** acceptance fails if installing that selection requires compiling them from source

#### Scenario: Preserve a newer Windows installation

- **WHEN** Korolev already has a newer Bitwarden CLI than the version initially installed
- **THEN** dry run accepts it and apply neither reinstalls nor downgrades it

### Requirement: Separate application-owned vault profiles

SCCH Vaultwarden and the private Bitwarden account SHALL use distinct persistent per-user directories selected through `BITWARDENCLI_APPDATA_DIR`. The SCCH profile SHALL use `https://password.scch.at`. Profile state SHALL stay outside repositories and temporary directories. Bitwarden SHALL own server configuration, credentials and sessions, which activation and chezmoi SHALL NOT write, copy or reset.

#### Scenario: Initialize the work profile

- **WHEN** the operator selects the SCCH directory and configures its server before interactive login
- **THEN** `bw config server https://password.scch.at` applies only to that profile
- **AND** private account state is unchanged

#### Scenario: Switch to the private account

- **WHEN** the operator clears the work session and selects the private directory
- **THEN** the private profile uses its independently configured server and login
- **AND** no work session or vault database is reused

#### Scenario: Reapply workstation configuration

- **WHEN** activation or chezmoi apply runs after both profiles have been configured
- **THEN** both profiles retain their application-owned state without credential transfer between hosts

### Requirement: Human-controlled vault authentication

Only the human SHALL perform interactive `bw login` and `bw unlock`, outside agent-visible terminals and tool capture. Master passwords and second factors SHALL NOT pass through the agent. Authentication and task credentials SHALL NOT be persisted in managed configuration, command arguments, chat or tracked files.

#### Scenario: Prepare access

- **WHEN** a task requires a vault item
- **THEN** the human selects and unlocks only the needed profile in a private terminal
- **AND** neither the agent nor its captured tools receive the master password or second factor

### Requirement: Pre-exported task secrets as the default

When required secrets are known in advance, the human SHALL export only those values under OMP-recognized secret variable names, lock the selected vault, clear session variables and then start OMP. The agent SHALL inherit the task secrets but no vault session. Failure to retrieve a value or lock the vault SHALL prevent startup.

#### Scenario: Supply the ANITA external vLLM key

- **WHEN** the human prepares the approved key before an ANITA task
- **THEN** the value is captured privately as `VLLM_API_KEY` before OMP starts
- **AND** `bw lock` completes and both `BW_SESSION` and `BW_SESSION_TOKEN` are absent from the agent environment
- **AND** the agent can use the named value without reading the rest of the vault

### Requirement: Operator-enabled provider-bound obfuscation

The human SHALL enable OMP `secrets.enabled` on each host before real secret use. Environment values SHALL be registered at OMP startup through recognized names and the supported minimum length. The procedure SHALL distinguish startup registration from built-in shape detection and SHALL NOT delegate OMP configuration or `secrets.yml` ownership to Nix or chezmoi.

#### Scenario: Register an otherwise unrecognized key shape

- **WHEN** a canary of at least eight characters that matches no built-in pattern is exported as `VLLM_API_KEY` before OMP starts with obfuscation enabled
- **THEN** its supported provider-bound text occurrences are placeholders rather than plaintext
- **AND** a tool can consume the restored value without printing it

#### Scenario: Enable obfuscation in an existing session

- **WHEN** obfuscation is enabled during a running session
- **THEN** the procedure does not claim that new environment values were collected at that time
- **AND** startup-dependent registration requires a fresh session

### Requirement: Secondary on-demand session access

On-demand retrieval SHALL be reserved for tasks whose required items are not known before startup. The human SHALL export the selected session as both `BW_SESSION` and the identical `BW_SESSION_TOKEN` before starting OMP with obfuscation enabled. Only that profile SHALL be available. The procedure SHALL state that the session grants whole-accessible-vault access and is not read-only or item-scoped.

#### Scenario: Protect the inherited session value

- **WHEN** an on-demand task starts
- **THEN** the matching-name alias registers the session value at startup without a broad shape regex
- **AND** no session value is printed, passed as a literal argument or persisted

#### Scenario: Retrieve an unregistered value after startup

- **WHEN** the agent fetches a value whose shape matches no built-in rule
- **THEN** the procedure treats it as unregistered even if it is assigned to a matching-name variable after startup
- **AND** it is delivered directly to a non-echoing consumer rather than exposed in tool output
- **AND** any workflow that needs to expose it to the model restarts with explicit startup registration before real use

### Requirement: Direct delivery and cleanup

The agent SHALL deliver values through a process-local environment, stdin, an in-process header or a private ignored file when required. Real values SHALL NOT be printed, logged, committed or placed in native command arguments. Cleanup SHALL clear task credentials and end inheriting processes. On-demand access SHALL additionally end with `bw lock` and removal of both session variables on success, failure or interruption.

#### Scenario: Consume a secret or report failure

- **WHEN** retrieval or consumption succeeds or fails
- **THEN** only a non-sensitive result is emitted and failed retrieval stops the consumer
- **AND** no environment dump, full item JSON, verbose header or secret-bearing diagnostic is enabled

#### Scenario: End access

- **WHEN** the task ends or is interrupted
- **THEN** derived values and session variables are cleared and inheriting processes end
- **AND** the on-demand profile is locked and subsequent retrieval without a new unlock fails noninteractively
- **AND** cleanup is not described as erasing previously delivered values or local recordings

### Requirement: Canary-gated real item use

Before real use, each flow on each host and vault used SHALL pass a human-created throwaway canary that matches no built-in secret pattern. The agent SHALL report whether supported provider-bound text contains a placeholder, plaintext or no value, and the human SHALL compare with the known canary. Plaintext exposure SHALL fail that tested path. Canary values SHALL NOT enter tracked or committed files.

#### Scenario: Accept the pre-export flow

- **WHEN** the human exports the canary under a matching name and starts OMP after locking the vault
- **THEN** a controlled canary-only output probe appears to the agent as a placeholder and the consumer succeeds with the restored value
- **AND** the human confirms the canary is absent from tracked and committed files before approving a real item

#### Scenario: Accept the constrained on-demand flow

- **WHEN** the agent pipes the unregistered canary directly from `bw get` into the intended non-echoing consumer
- **THEN** neither its success nor its exercised failure path exposes the canary in provider-bound text
- **AND** the agent reports no value at those output points and the human confirms the result
- **AND** a plaintext canary in any tested output blocks real use of that path until corrected and retested

#### Scenario: Finish canary checks

- **WHEN** both flows have been exercised or an unsafe path has been rejected
- **THEN** the human deletes the throwaway vault entry and clears the canary environments
- **AND** future regression checks create a fresh canary rather than reuse an accepted credential

### Requirement: Explicit obfuscation and local-state limits

The procedure SHALL limit obfuscation claims to supported provider-bound text for registered or pattern-matching values. It SHALL explain tool-argument restoration, plaintext local display/resume and terminal/session persistence. Obfuscation SHALL NOT be presented as a sandbox, local-storage encryption or universal leak prevention. Local state SHALL remain application-owned.

#### Scenario: Inspect local canary persistence

- **WHEN** the human checks Tern terminal state and OMP local session storage with a canary
- **THEN** the actual locations and plaintext restore or persistence behavior are identified without copying real secrets into artifacts
- **AND** the procedure warns that local records can retain plaintext even when the provider receives placeholders

#### Scenario: Review consent for the secondary flow

- **WHEN** the human considers on-demand access
- **THEN** the procedure explains whole-vault exposure, unregistered fetched-value risk and optional server-side account restrictions
- **AND** a collection filter or local profile directory is not represented as an item-scoped security boundary
