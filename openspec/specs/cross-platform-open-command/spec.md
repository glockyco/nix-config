# Cross-Platform Open Command Specification

## Purpose

Provide a predictable Korolev `open` command that sends local targets to the Windows graphical desktop without crossing configuration ownership boundaries.

## Requirements

### Requirement: Korolev open command

Korolev's NixOS/WSL login shell SHALL provide a managed `open [target]` command without manual shell initialization. The interface SHALL accept no target or one target. Multiple targets are outside this contract.

#### Scenario: Resolve the command in WSL

- **WHEN** the user starts a fresh Korolev login shell
- **THEN** `open` resolves to the Nix-managed WSL command

### Requirement: Target dispatch

With no target, `open` SHALL dispatch the current directory. With one existing Linux file or directory, it SHALL dispatch that exact target. With one absolute URI, it SHALL dispatch the URI to the Windows desktop's registered handler. Dispatch SHALL return after the Windows shell accepts or rejects the request. It SHALL NOT wait for the graphical application to exit.

#### Scenario: Open the current directory

- **WHEN** the user runs `open` without a target
- **THEN** the Windows desktop opens the current directory

#### Scenario: Open a path with spaces

- **WHEN** the user passes one existing file or directory whose path contains spaces
- **THEN** the Windows desktop opens that exact target as one argument

#### Scenario: Open an absolute URI

- **WHEN** the user passes an absolute URI with a registered Windows handler
- **THEN** the registered Windows application receives that URI

#### Scenario: Reject an invalid target

- **WHEN** the user passes a value that is neither an existing local target nor an absolute URI
- **THEN** `open` returns a nonzero status with a clear error
- **AND** it launches no substitute target

### Requirement: WSL uses the Windows desktop boundary

`open` SHALL translate an existing Linux path to its absolute Windows form and pass one target directly to the Windows graphical shell. It SHALL pass an absolute URI unchanged. It SHALL NOT use a command interpreter, WSLg application, executable fallback, or `wslu` utility.

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

### Requirement: Activation boundary

Nix activation SHALL only install the WSL-side command. It SHALL NOT write a Windows path or launch a graphical application.

#### Scenario: Activate Korolev

- **WHEN** the operator activates the NixOS configuration
- **THEN** the WSL command becomes available after activation
- **AND** activation writes no Windows file and opens no graphical target
