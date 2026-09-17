## Why

PDF inspection currently requires an ad hoc renderer because `pdftoppm` is unavailable. The shared document-tooling module should supply standard PDF inspection commands on both managed workstations.

## What Changes

- Add `pkgs.poppler-utils` to `modules/home/tex.nix` beside the existing TeX tooling.
- Verify PDF rendering with the pinned package and evaluate both host package sets.
- Keep document builds in their owning repositories. Do not activate hosts or update flake inputs.

## Capabilities

### New Capabilities

- `pdf-inspection-tools`: Workstation commands for PDF rasterization and inspection.

### Modified Capabilities

None.

## Impact

The shared Home Manager TeX module gains one package. No manuscript, project build configuration, or Windows application policy changes. Activation remains a separate operation after review.
