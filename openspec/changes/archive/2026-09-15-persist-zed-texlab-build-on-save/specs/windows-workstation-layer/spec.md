## ADDED Requirements

### Requirement: Zed WSL LaTeX builds

The rendered Windows Zed user settings SHALL enable TexLab builds when a LaTeX buffer is saved. The setting SHALL apply to LaTeX projects opened through Zed's native WSL workspace transport. Project repositories SHALL retain ownership of their build commands, root-document markers, and LaTeX tool configuration.

#### Scenario: Build a WSL LaTeX project after save

- **WHEN** the operator saves a LaTeX source file in a Zed WSL workspace
- **THEN** Zed sends TexLab a workspace configuration with build-on-save enabled
- **AND** TexLab invokes the WSL project's declared LaTeX build

#### Scenario: Preserve project build ownership

- **WHEN** two LaTeX repositories use different build commands or output directories
- **THEN** each repository supplies those details through its own LaTeX configuration
- **AND** the Windows Zed setting does not embed either repository's paths
