## Context

The shared Home Manager configuration composes the user package set for both managed hosts. Raw cross-platform packages belong in `modules/home/packages.nix`; project dependencies remain in their owning repositories.

## Goals / Non-Goals

**Goals:**

- Put one pinned `uv` executable on each managed user's normal `PATH`.
- Reuse the existing shared package declaration and activation path.

**Non-Goals:**

- Manage project Python dependencies or virtual environments from Nix.
- Add another project development shell or imperative installer.
- Activate either host as part of the repository change.

## Decisions

Declare `pkgs.uv` beside the existing raw shared packages in `modules/home/packages.nix`. Home Manager already places this package set in the user profile on both hosts, so no new module or wrapper is necessary.

Keep each repository's `pyproject.toml`, lockfile, and local environment authoritative for project dependencies. The global package supplies only the bootstrap command.

## Risks / Trade-offs

The shared user profile gains the closure size of `uv` and its runtime dependencies. In return, project instructions can use one direct command in normal login shells on both hosts.
