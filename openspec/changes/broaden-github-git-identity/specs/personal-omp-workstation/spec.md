## MODIFIED Requirements

### Requirement: Repository-specific Git identity

The WSL host SHALL declare `johann.glock@scch.at` as the global Git email. It SHALL declare `11704293+glockyco@users.noreply.github.com` for every Git worktree below `~/src/github.com/` through a conditional Git include. The global email SHALL remain effective below `~/src/gitlab.scch.at/` and outside the GitHub tree unless a repository-local email overrides it. A repository-local `user.email` SHALL override both declared identities. Activation SHALL NOT write repository-local Git configuration.

#### Scenario: Bootstrap with a work email

- **WHEN** the WSL host declares `johann.glock@scch.at` as the global Git email
- **AND** the user inspects the effective email in a GitHub worktree
- **THEN** Git reports `11704293+glockyco@users.noreply.github.com`
- **AND** the global Git email remains `johann.glock@scch.at`

#### Scenario: Commit in a personal repository

- **WHEN** the user commits in a Git worktree below `~/src/github.com/`
- **THEN** Git uses `11704293+glockyco@users.noreply.github.com`
- **AND** the result does not depend on the repository owner

#### Scenario: Commit outside a personal repository tree

- **WHEN** the user commits in a Git worktree below `~/src/gitlab.scch.at/`
- **THEN** Git uses `johann.glock@scch.at`

#### Scenario: Use a repository-local override

- **WHEN** a repository below either declared host tree has a repository-local `user.email`
- **THEN** Git uses the repository-local email

#### Scenario: Inspect a fresh checkout

- **WHEN** the user clones a repository below `~/src/github.com/` after activation
- **THEN** Git reports the GitHub no-reply address without repository-local Git configuration
