# Spec Delta

## MODIFIED Requirements

### Requirement: Shared user-scope module set

Both supported hosts SHALL consume one portable chezmoi source for shell behavior, Git, the GitHub CLI and repository-root configuration, with ordinary user packages declared by their system configuration. Platform program modules SHALL own shell plugins. Mac-only user setup SHALL apply only to Darwin. Home Manager SHALL own no packages, files or activation steps.

#### Scenario: Build the shared set on both hosts

- **WHEN** each host configuration is built
- **THEN** both install the shared ordinary user packages and render the portable chezmoi source
- **AND** the WSL host applies no Darwin user setup

#### Scenario: Add a portable module

- **WHEN** portable user configuration changes
- **THEN** the change applies to both hosts without a second declaration
