## ADDED Requirements

### Requirement: Native PowerShell shell tools

The Windows application set SHALL declare Starship from its official release archive, zoxide and eza as WinGet packages, and PSFzf and git-completion as PowerShell Gallery modules. Each SHALL install in the standard user's scope with present policy and its own application role. None SHALL use a machine-scope installer, request elevation or install into the Windows PowerShell 5.1 module path.

#### Scenario: Install the shell tools

- **WHEN** the standard user applies the declarations on a workstation without these tools
- **THEN** a fresh PowerShell 7 session resolves `starship`, `zoxide` and `eza` from PATH
- **AND** PSFzf and git-completion import from the PowerShell 7 current-user module path
- **AND** no step requests Administrator credentials

#### Scenario: Reject a competing declaration

- **WHEN** data installs Starship through a machine-scope installer or assigns a shell-tool role to another application
- **THEN** validation fails before any change and names the application or role

#### Scenario: Keep a newer tool

- **WHEN** an installed shell tool or module is newer than its reviewed release
- **THEN** dry run reports it as desired
- **AND** apply neither reinstalls nor downgrades it

### Requirement: PowerShell Gallery module delivery

A PowerShell Gallery module declaration SHALL name the module, its reviewed release version and the SHA-256 of that release's package. A module SHALL be desired when the PowerShell 7 current-user module path holds it at the reviewed or a newer version. Apply SHALL install a missing module only from the reviewed package after verifying its hash and manifest version. Delivery SHALL NOT change PATH, register or trust a repository, or replace a newer installed version.

#### Scenario: Install a missing module

- **WHEN** apply runs while a declared module is absent
- **THEN** the reviewed package is downloaded and its hash verified before extraction
- **AND** the module manifest in the current-user module path reports the reviewed version
- **AND** a fresh PowerShell 7 session imports the module by name

#### Scenario: Reject a mismatched package

- **WHEN** the downloaded package hash or its manifest version differs from the declaration
- **THEN** apply fails and names the module
- **AND** the current-user module path is unchanged

#### Scenario: Preview a missing module

- **WHEN** dry run runs while a declared module is absent
- **THEN** it reports the module as drift without downloading or writing files
