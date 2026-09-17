## Context

See proposal.md for motivation. `modules/home/tex.nix` already owns TeX Live, TexLab, Pygments, and spelling tools.

## Goals / Non-Goals

Provide PDF inspection beside document tooling on both managed hosts. Do not change project builds, flake inputs, or host activation state.

## Decisions

Add `pkgs.poppler-utils` to the existing shared package list. Use the pinned nixpkgs package rather than a Python renderer or a separate module. Run a real PDF-to-PNG smoke and inspect its output.

## Risks / Trade-offs

The package adds closure size. Availability before activation is limited to explicit Nix package execution. Follow the README release gates; macOS runtime verification requires that host. No automatic activation is authorized.
