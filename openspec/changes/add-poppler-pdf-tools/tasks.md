## 1. Configuration

- [x] 1.1 Add `pkgs.poppler-utils` to `modules/home/tex.nix`; evaluate both host package sets and confirm the package is included.

## 2. Verification

- [x] 2.1 Build the pinned Linux package and exercise `pdftoppm`, `pdfinfo`, and `pdftotext` on a real PDF; inspect the rendered page and record results in this change.
- [x] 2.2 Run `openspec validate add-poppler-pdf-tools --strict`, then the README formatting and applicable flake checks sequentially; record unavailable host-specific gates without claiming they passed.
- [x] 2.3 Inspect and commit only the verified change. Leave pushes, activation, and archival to separately authorized operations.

## Verification evidence

- Both host Home Manager package sets evaluate with `poppler-utils-26.06.0`: x86_64-linux and aarch64-darwin. The pinned nixpkgs rejects the former `poppler_utils` alias; the declaration uses `poppler-utils`.
- The selected Linux package builds successfully. Its `pdfinfo` reports an eight-page manuscript. `pdftotext` extracts the expected title. `pdftoppm -f 1 -singlefile -scale-to 1200 -png` renders the first page; visual inspection confirms readable text and the two-column layout. Temporary outputs were removed.
- `openspec validate add-poppler-pdf-tools --strict` passes.
- `nix fmt -- --fail-on-change` passes with no changes.
- `nix flake check --print-build-logs` passes on x86_64-linux, including the Korolev system and Home Manager generation builds.
- Darwin package inclusion was evaluated, but Darwin build-plan checks, system build, and runtime smoke were not run from this Linux session. Those host-specific release gates remain required before Mac deployment.
- No flake inputs changed. No host was activated, and no commit was pushed. Commands become available on the normal user PATH after a separately authorized activation.
