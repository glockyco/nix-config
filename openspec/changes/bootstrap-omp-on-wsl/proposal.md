## Why

The new Windows work machine cannot activate the macOS-only `nix-darwin` host, but the personal OMP package already evaluates for `x86_64-linux`. A focused WSL bootstrap must make the wrapped OMP environment usable first, so later workstation work can be planned and executed from that machine.

## What Changes

- Add a documented, cold-start path from Windows to the locked `personal-omp` and OpenSpec packages in WSL 2.
- Recommend Windows Terminal Stable as the native host with Ubuntu WSL 2 as its default profile, without making the repository manage the Windows application or its settings.
- Define the unavoidable manual bootstrap boundary: enable WSL 2, create the Linux user, install Nix, obtain the repository, and authenticate OMP when prompted.
- Publish the existing Numtide substituter and signing key from the root flake so Linux installs can fetch the locked OMP build instead of compiling it because an input flake's cache settings are not inherited.
- After Nix is available, expose one supported command that installs or updates the user profile, initializes only the minimal OMP directory required by Herdr, reconciles Herdr, and verifies the immutable plugin without a Darwin activation or prior OMP launch.
- Configure this repository checkout to use the private GitHub no-reply email without replacing the WSL user's global work email.
- Keep OMP authentication, preferences, sessions, history, and caches as writable WSL-local state.
- Add Linux checks for the bootstrap command and a release gate for one real wrapped OMP session on WSL.
- Limit the first cut to `x86_64-linux` under WSL 2. Do not manage Windows applications, Windows policy, project toolchains, or game deployment.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `personal-omp-workstation`: Extend the workstation contract with a supported WSL bootstrap, WSL-local mutable state, deterministic verification, and a real-session acceptance gate.

## Impact

The change affects the root flake cache contract, flake outputs, the personal OMP package helpers, repository-local Git configuration, Linux checks, operator documentation, and the `personal-omp-workstation` contract. It uses the existing locked OMP, Herdr, OpenSpec, plugin, and language-server inputs. It documents Windows Terminal Stable as a manual host prerequisite, but it does not install or configure Windows applications. It does not activate `nix-darwin` or Home Manager on WSL, and it does not alter the current Mac host.
