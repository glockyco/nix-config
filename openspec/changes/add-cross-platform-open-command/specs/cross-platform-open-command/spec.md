## Purpose

Provide one predictable `open` command that sends local targets to each workstation's graphical desktop without crossing configuration ownership boundaries.

## ADDED Requirements

### Requirement: Common open command

Each supported interactive environment SHALL provide `open [target]`. macOS SHALL keep its platform command. Korolev's NixOS/WSL shell and native Windows PowerShell 7 SHALL provide managed implementations without manual shell initialization.

The portable interface SHALL accept no target or one target. Platform-specific options and multiple targets are outside this contract.

#### Scenario: Resolve the command on macOS

- **WHEN** the user starts a fresh macOS login shell
- **THEN** `open` resolves to the platform-provided macOS command
- **AND** the workstation configuration has not replaced it with a compatibility wrapper

#### Scenario: Resolve the command in WSL

- **WHEN** the user starts a fresh Korolev login shell
- **THEN** `open` resolves to the Nix-managed WSL command

#### Scenario: Resolve the command on Windows

- **WHEN** the user starts a fresh native PowerShell 7 session
- **THEN** `open` resolves to the user-scoped Windows command without a manually edited profile

### Requirement: Target dispatch

With no target, `open` SHALL dispatch the current directory. With one existing local file or directory, it SHALL dispatch that exact target. With one absolute URI, it SHALL dispatch the URI to the desktop's registered handler. Dispatch SHALL return after the platform accepts or rejects the request; it SHALL NOT wait for the graphical application to exit.

#### Scenario: Open the current directory

- **WHEN** the user runs `open` without a target
- **THEN** the graphical desktop opens the current directory

#### Scenario: Open a path with spaces

- **WHEN** the user passes one existing file or directory whose path contains spaces
- **THEN** the graphical desktop opens that exact target as one argument

#### Scenario: Open an absolute URI

- **WHEN** the user passes an absolute URI with a registered desktop handler
- **THEN** the registered application receives that URI

#### Scenario: Reject an invalid target

- **WHEN** the user passes a value that is neither an existing local target nor an absolute URI
- **THEN** `open` returns a nonzero status with a clear error
- **AND** it launches no substitute target

### Requirement: WSL uses the Windows desktop boundary

On Korolev, `open` SHALL translate an existing Linux path to its absolute Windows form and pass one target directly to the Windows graphical shell. It SHALL pass an absolute URI unchanged. It SHALL NOT use a command interpreter, WSLg application, executable fallback, or `wslu` utility.

#### Scenario: Dispatch a Linux path to Windows

- **WHEN** the user runs `open` with an existing Linux path
- **THEN** the Windows shell receives the corresponding absolute Windows path
- **AND** no Linux graphical application handles the target

#### Scenario: Preserve shell metacharacters

- **WHEN** an existing Linux target contains spaces or command-shell metacharacters
- **THEN** the Windows shell receives the complete translated path as one inert argument
- **AND** no part of the target is evaluated as a command

#### Scenario: Windows interoperation is unavailable

- **WHEN** path translation or Windows executable interoperation is unavailable
- **THEN** `open` returns a nonzero status that identifies the unavailable boundary
- **AND** it does not install, select, or invoke a fallback opener

### Requirement: Native Windows uses registered associations

The native Windows command SHALL use PowerShell 7 and the Windows shell's registered associations. The rendered Windows configuration SHALL install it in the interactive user's scope and SHALL NOT modify a PowerShell profile to make the command discoverable.

#### Scenario: Open a native Windows target

- **WHEN** the user passes an existing Windows file or directory to `open`
- **THEN** Windows opens that target through its registered shell association

#### Scenario: Preserve an unrelated profile

- **WHEN** the Windows command is installed or updated
- **THEN** the operation does not create, replace, or amend any PowerShell profile

### Requirement: Explicit activation boundaries

Nix activation SHALL only prepare the WSL-side command. It SHALL NOT write a Windows path or launch a graphical application. The rendered Windows configuration SHALL install the native command only during an explicit user-scoped Windows apply. Applying either configuration SHALL NOT dispatch a target.

#### Scenario: Activate Korolev

- **WHEN** the operator activates the NixOS configuration
- **THEN** the WSL command becomes available after activation
- **AND** activation writes no Windows file and opens no graphical target

#### Scenario: Apply the Windows configuration

- **WHEN** the operator applies the rendered Windows configuration in a standard PowerShell session
- **THEN** the native Windows command is installed for that user without elevation
- **AND** the apply operation opens no graphical target
