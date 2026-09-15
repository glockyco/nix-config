## 1. Declare editor policy

- [x] 1.1 Add TexLab build-on-save to the Windows Zed settings overlay; evaluate the rendered JSON.
- [x] 1.2 Remove the ineffective repository-local TexLab workspace setting while retaining the repository's LaTeX root and build configuration; inspect both repositories' diffs.

## 2. Verify behavior

- [x] 2.1 Run strict OpenSpec validation and the focused Windows configuration check.
- [x] 2.2 Apply the managed Zed settings to the live Windows user profile, inspect the effective Zed-to-TexLab configuration, and confirm that saving an included LaTeX file rebuilds the root PDF without diagnostics.

## 3. Preserve revision history

- [x] 3.1 Commit the nix-config declaration, planning artifacts, and verification evidence as one atomic change with a causal body.
- [x] 3.2 Commit the paper repository cleanup separately after verifying that the manuscript still builds.
