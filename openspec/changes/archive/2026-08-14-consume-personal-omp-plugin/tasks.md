## 1. Pin immutable inputs

- [x] 1.1 Add the published `omp-agent-setup` plugin flake as an independently locked workstation input.
- [x] 1.2 Assert that the input's default package is a valid OMP plugin directory on the supported workstation system.

## 2. Compose the default runtime

- [x] 2.1 Package one `omp` wrapper that targets the pinned upstream binary and immutable plugin store path.
- [x] 2.2 Add the curated C#, Python, TypeScript/JavaScript, Svelte, Nix, Markdown, and LaTeX/BibTeX server executables to the wrapper runtime.
- [x] 2.3 Replace direct installation of the upstream OMP package with the default wrapper while preserving the independent Herdr package.
- [x] 2.4 Add pure checks for wrapper targets, plugin shape, minimal LSP overrides, command precedence, and absence of mutable source paths.

## 3. Preserve and reconcile mutable state

- [x] 3.1 Add an activation entry that leaves OMP configuration, authentication, sessions, history, caches, and logs in place.
- [x] 3.2 Reconcile a missing or outdated OMP integration through the pinned Herdr CLI and leave a current integration untouched.
- [x] 3.3 Add activation tests for current, missing, and stale Herdr integration states without copying Herdr's payload.

## 4. Prove the cutover

- [x] 4.1 Build and activate the workstation generation with the wrapped OMP command.
- [x] 4.2 Run the fixed representative language-server matrix through the packaged runtime.
- [x] 4.3 Launch one real wrapped OMP session in a disposable repository and verify plugin path, personal policy, tool registration, and non-mutating preview behavior.
- [x] 4.4 Verify preserved mutable state and current Herdr integration after activation.
