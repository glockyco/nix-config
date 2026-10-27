## Why

omp-agent-setup selects Bun 1.4.4 in `.bun-version`, and its pre-commit and pre-push hooks run `bun`. Korolev has that Bun through the Windows application declaration, but the Mac has none in login shells, so OMP's commit tool cannot pass the hooks there and every session needs a separately downloaded copy.

## What Changes

- Add a `bun-bin` package built from Bun's official macOS release archive with a fixed hash, at the version that Korolev's declaration pins for omp-agent-setup.
- Install it among the Mac's ordinary user packages.
- Add a check that fails when the Mac's Bun version and the Windows declaration's Bun version differ.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `personal-omp-workstation`: The Mac provides the Bun that the personal plugin repository selects.

## Impact

After activation, `bun` resolves in Mac login shells and in OMP, including its commit tool. nixpkgs' own Bun stays in place for packages that build with it.
