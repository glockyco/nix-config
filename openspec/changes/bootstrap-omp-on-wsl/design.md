## Context

See `proposal.md` for motivation and `specs/personal-omp-workstation/spec.md` for the WSL contract.

The flake already evaluates `personal-omp`, OpenSpec, and the existing deterministic OMP checks for `x86_64-linux`. `packages/personal-omp.nix` also exposes the Herdr reconciliation and local verification helpers as passthrough derivations. Darwin Home Manager calls those helpers during activation, but WSL has no activation path. The complete Home Manager import graph contains unguarded macOS modules, so reusing it would expand this change into a workstation port.

Windows Terminal Stable is the selected native terminal host. Its Ubuntu WSL 2 dynamic profile crosses into the Linux environment without adding a graphical terminal inside WSL. Windows owns the terminal application and fonts; WSL owns the shell, Nix, OMP, and repositories.

The bootstrap begins only after the operator installs or updates Windows Terminal Stable, enables WSL 2, creates the Linux user, installs Nix, and obtains the locked repository. Provider authentication remains an interactive OMP operation after deterministic bootstrap. Employer policy approval is an operator prerequisite, not a condition that repository code can discover.

## Goals / Non-Goals

**Goals:**

- Use Windows Terminal Stable as the maintained native host for the Ubuntu WSL 2 OMP session.
- Turn the existing Linux package outputs into one repeatable post-Nix bootstrap command.
- Install one coherent user-profile entry instead of independent packages that can drift.
- Preserve the previous working profile generation when reconciliation or verification fails.
- Reuse the same wrapper, plugin, helpers, and checks as the Darwin host.
- Produce enough local evidence before the model-backed WSL smoke.

**Non-Goals:**

- Introduce a Linux Home Manager host or split the current Home Manager module graph.
- Install Nix, enable WSL, configure Windows, or bypass employer policy.
- Transfer OMP databases or credentials from the Mac.
- Support Windows on ARM, native Windows OMP, project shells, or game workflows.
- Automate a provider-backed smoke in CI.

## Decisions

### 1. Use Windows Terminal Stable as the native host

The operator will use the stable Microsoft distribution of Windows Terminal and set its generated Ubuntu WSL 2 profile as the default. The profile will start in the Linux user's home directory. Windows owns the emulator and font configuration; WSL owns the shell, Nix profile, OMP state, and repositories.

The first bootstrap will retain Windows Terminal's normal keybindings. OMP already documents `Alt+V` when the terminal handles `Ctrl+V`, `Ctrl+Q` when it handles `Ctrl+Enter`, and `Alt+Shift+V` when it handles raw paste. The runbook will use these application fallbacks instead of overriding global terminal behavior. It will not set forced image, keyboard, width, or redraw environment variables. The real-session smoke will determine whether automatic terminal capability detection works.

The initial font will be Cascadia Mono. A Nerd Font belongs to the later shell and prompt port, not the OMP bootstrap. Windows Terminal tabs and panes are sufficient for the local session, so the bootstrap will not add `tmux`.

**Alternatives considered:**

- WezTerm provides stronger cross-platform configuration and terminal protocols, but its tagged stable release cadence does not justify replacing the maintained Windows default for this bootstrap.
- Alacritty is fast and minimal, but it delegates tabs and panes to another component and still describes itself as beta.
- Ghostty has no official native Windows distribution. Running its Linux GUI through WSLg adds an unnecessary display boundary.
- An editor-integrated terminal couples OMP to the editor lifecycle and shortcut map. It remains useful for short commands, not the primary session.
- Windows Terminal Preview or Canary adds pre-release behavior without a capability required by the accepted OMP contract.

### 2. Export one WSL environment package and one bootstrap application

The flake will export an `x86_64-linux` environment package containing the existing `omp` wrapper, OpenSpec, and the reconciliation and verification helpers. It will also export a bootstrap application, invoked from the locked checkout as:

```sh
nix run .#bootstrap-omp-on-wsl
```

The environment becomes one named Nix profile entry. This prevents OMP and OpenSpec from advancing independently and gives the bootstrap one replacement and rollback unit.

The application will reject non-WSL and non-`x86_64-linux` hosts before profile mutation. Platform detection will use WSL's documented runtime markers rather than infer support from the Windows filesystem mount.

**Alternatives considered:**

- Install `personal-omp` and OpenSpec as two profile entries. This permits partial updates and complicates re-entry.
- Add a WSL Home Manager configuration. This requires a portable-versus-Darwin module split that is unnecessary for the first usable session.
- Publish a PowerShell installer. PowerShell cannot own the Linux Nix profile or remove the manual WSL and Linux-user boundary.

### 3. Make profile replacement transactional

The bootstrap will build the selected environment before it changes the user profile. It will then install the named entry on a clean profile or replace that entry on re-entry. After the profile switch, it will run the packaged Herdr reconciliation helper and the packaged verifier.

The bootstrap will record the previous profile generation. If reconciliation or verification fails, it will restore that generation. When a previous personal OMP environment exists, it will reconcile and verify the restored environment before reporting failure. On a first installation failure, it will remove the failed profile generation and report any WSL-local mutable artifact that requires operator inspection.

The bootstrap will never run `nix flake update`, modify `flake.lock`, or select packages outside the current locked checkout.

**Alternatives considered:**

- Call `nix profile upgrade --all`. This can change unrelated user packages and can follow unlocked sources outside this repository.
- Treat a failed post-install verification as a warning. That leaves `omp` resolving to an unaccepted environment.
- Delete and recreate the whole user profile. That violates ownership of unrelated packages.

### 4. Keep mutable state local and narrowly touched

The command will use the WSL user's normal `HOME`. It will not accept a Mac state archive or add a migration option. The only intentional write below `~/.omp/agent` is Herdr's generated integration through `herdr integration install omp` when the existing helper determines that installation is missing or stale.

Tests will set temporary homes and profiles. They will assert that unrelated files, configuration, and database sentinels retain their type, contents, and metadata across clean, current, stale, and failed bootstrap paths.

**Alternatives considered:**

- Copy the Mac `~/.omp/agent` directory. This transfers provider credentials and unverified database state across trust and operating-system boundaries.
- Make OMP configuration immutable through Home Manager. This contradicts the existing OMP ownership boundary.

### 5. Separate deterministic proof from the real WSL smoke

Linux flake checks will cover package composition, platform rejection, clean installation, re-entry, locked-revision replacement, Herdr reconciliation, verification failure, rollback, and mutable-state preservation. Command tests will use explicit temporary profiles and controlled tool doubles where nested Nix profile operations cannot run in a sandbox. Existing package-shape checks will continue to inspect the real selected closures.

The final acceptance gate will run on the Windows machine. The operator will record the Windows version, WSL version, distribution, architecture, and repository revision. A disposable repository and a fresh wrapped session will prove the immutable plugin path, personal policy, and harmless `personal_commit` preview.

**Alternatives considered:**

- Declare support after `nix build` on ordinary Linux. That does not exercise WSL, the user profile, Herdr's mutable integration, or an interactive OMP session.
- Put a provider credential in CI. That adds secret and usage risk without proving the actual workstation boundary.

### 6. Keep the runbook procedural and WSL-specific

A focused operations document will first install or update Windows Terminal Stable through the employer-managed or Microsoft-supported channel. It will set the generated Ubuntu WSL 2 profile as the default, retain normal terminal keybindings, and use the Linux home directory. The procedure will then start in Administrator PowerShell for WSL enablement, cross into the Linux shell, install Nix through the selected supported installer, obtain the repository, and run the one bootstrap command. It will include exact deterministic checks, OMP's Windows Terminal key fallbacks, the interactive smoke, update re-entry, failure recovery, and the unsupported-architecture stop.

The document will guide manual Windows Terminal settings, but it will not claim that this repository installs or manages Windows Terminal, VS Code, GitHub authentication, corporate controls, or OMP provider approval.

## Risks / Trade-offs

- **[The work machine blocks WSL, Nix, GitHub, a binary cache, or the model provider]** → State those as prerequisites and stop before repository-owned mutation; do not add bypasses.
- **[WSL detection changes across Windows releases]** → Test documented markers and fail closed with diagnostic output.
- **[Nix profile JSON or command behavior differs from the tested Determinate Nix release]** → Parse structured output, check the minimum supported interface, and fail before replacement when it is incompatible.
- **[Post-switch Herdr reconciliation mutates state before later verification fails]** → Roll back the Nix profile, reconcile the restored package when available, and report the mutable extension state explicitly.
- **[A combined environment package collides with another profile package]** → Keep the bundle limited to its four owned commands and fail on profile conflicts instead of changing priorities globally.
- **[Windows Terminal intercepts an OMP key chord]** → Use OMP's documented `Alt+V`, `Ctrl+Q`, and `Alt+Shift+V` fallbacks; do not override terminal-wide keys during bootstrap.
- **[Terminal capability detection selects a broken rendering path]** → Exercise the real TUI without forced protocol variables and treat a rendering defect as failed acceptance evidence.
- **[Linux checks pass but WSL interoperability fails]** → Keep the real WSL session as a mandatory acceptance gate.
- **[The first bootstrap becomes an accidental general Windows installer]** → Keep Windows actions manual and defer broader workstation ownership to a separate change.

## Migration Plan

1. Add the combined Linux environment package and bootstrap application without changing Darwin outputs.
1. Add deterministic Linux checks for the bootstrap state machine, rollback, and mutable-state boundary.
1. Run the repository release gates on the Mac and the existing `x86_64-linux` check environment.
1. Install or update Windows Terminal Stable, select its Ubuntu WSL 2 profile, and follow the WSL runbook from the reviewed locked revision.
1. Complete the real wrapped-session smoke and record the terminal, platform, and revision evidence.
1. Retain the previous Nix profile generation until the WSL smoke passes.

If bootstrap fails, its automatic rollback restores the prior profile generation. On a clean machine, remove only the failed named profile entry. Do not delete `~/.omp/agent`; inspect and preserve it as user-owned state.
