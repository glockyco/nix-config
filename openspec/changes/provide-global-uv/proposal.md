## Why

Managed login shells do not provide `uv`, although project instructions use it to create locked Python environments. The coding harness masked this gap because its private development environment supplies `uv` independently.

## What Changes

- Install the pinned Nixpkgs `uv` package through the shared Home Manager package set.
- Make the same `uv` command available on every managed host without installing project dependencies globally.
- Verify the shared Home Manager package declaration and both host configurations.

## Capabilities

### New Capabilities

- `python-project-tooling`: Defines the globally available bootstrap tool for project-local Python environments.

### Modified Capabilities

None.

## Impact

- `modules/home/packages.nix` gains one shared package.
- Mac and Korolev user profiles gain the Nixpkgs `uv` executable.
- Project Python dependencies remain owned by each repository and its lockfile.
