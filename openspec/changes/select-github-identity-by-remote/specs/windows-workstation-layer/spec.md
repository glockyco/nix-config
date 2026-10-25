## MODIFIED Requirements

### Requirement: Native checkout and user ownership

Korolev SHALL use a native Windows checkout below the ghq root `~/src` as chezmoi `sourceDir`, selecting host `korolev` and Windows-specific shared facts. Git and SSH files SHALL reuse the shared templates; Zed SHALL preserve app-owned state. User apply SHALL not configure OpenSSH services or copy credentials from another platform; privileged package exceptions SHALL remain explicitly approved.

#### Scenario: Apply from the native checkout

- **WHEN** the standard Windows account initializes chezmoi from its local checkout
- **THEN** `.chezmoiroot` selects `home/` and the recorded `sourceDir` remains that checkout
- **AND** Windows username/home paths do not resolve to the WSL user's paths
- **AND** repeating apply preserves undeclared application state and writes no Administrator-profile file

#### Scenario: Select Git identity

- **WHEN** Git runs in a repository whose remote points at github.com, in a repository below `~/src/github.com/`, or in any other repository
- **THEN** the first two use `11704293+glockyco@users.noreply.github.com` and the others use global `johann.glock@scch.at`
- **AND** a repository-local email overrides either selection
- **AND** Git uses Windows GCM and preserves the Overleaf generic-provider declaration

#### Scenario: Commit from a GitHub clone outside the GitHub tree

- **WHEN** a repository cloned from github.com over HTTPS or SSH lives outside `~/src/github.com/`, such as a scratch directory
- **THEN** its commits use `11704293+glockyco@users.noreply.github.com`
- **AND** a repository outside that tree with a gitlab.scch.at remote keeps `johann.glock@scch.at`

#### Scenario: Apply package configuration after a source change

- **WHEN** the workstation declaration or engine changes and the standard user runs `chezmoi apply`
- **THEN** a content-hashed onchange operation runs the PowerShell 7 workstation engine from the checkout and propagates failure
- **AND** an unchanged apply does not rerun that operation
- **AND** the Administrator scripts remain explicit elevated runs
