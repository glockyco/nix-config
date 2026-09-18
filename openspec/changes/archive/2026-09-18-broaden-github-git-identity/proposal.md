## Why

Korolev applies the GitHub no-reply address only to repositories owned by `glockyco`. Repositories under other owners in `~/src/github.com/` can therefore create commits with the global SCCH address.

## What Changes

- Apply `11704293+glockyco@users.noreply.github.com` to every Git worktree under `~/src/github.com/` on Korolev.
- Keep `johann.glock@scch.at` as the global email and effective default for repositories under `~/src/gitlab.scch.at/` and other locations.
- Preserve repository-local `user.email` overrides.
- Verify the effective identity in representative GitHub, SCCH GitLab, and locally overridden repositories.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `personal-omp-workstation`: Broaden Korolev's conditional Git identity from one GitHub owner tree to the complete GitHub host tree.

## Impact

- Affects Korolev's Home Manager Git declaration in `hosts/korolev/default.nix`.
- Affects the WSL bootstrap guidance and the repository-specific identity contract.
- Adds no package, credential, network dependency, activation side effect, or repository-local configuration.
