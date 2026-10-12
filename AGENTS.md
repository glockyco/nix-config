# Repository guidance

The [README](README.md) covers hosts, checks, activation, updates and recovery. The guides in [docs/operations](docs/operations/) cover each host and recurring procedure. Read declarations for configuration facts.

## Changes

Use OpenSpec for permanent behavior changes. Read all artifacts of the selected change before editing implementation files. Validate with `openspec validate <change> --strict` and archive only after every acceptance gate passes. Accepted contracts live in `openspec/specs/`. An unchecked task or an `in-progress` status does not authorize deferred work.

The personal plugin owns the OpenSpec adapters, and its workflow commands are `/personal:opsx-*`. Do not run `openspec init` here. The `personal-omp-plugin` input only supplies the OpenSpec checks.

[docs/plans](docs/plans/INDEX.md) holds old plans. Keep them until a reviewed change replaces them.

## Boundaries

- Nix owns packages and host configuration on macOS and Linux, never OMP. OMP comes from its official installer on macOS and from Tern on Windows, and the plugin manager installs its plugins. Do not add wrappers, launcher flags, patched sources or activation steps that install, update or reconfigure OMP.
- Chezmoi owns user files from `home/`. Read shared TOML facts through the typed host registry in Nix and directly in templates, and never duplicate them. The system switch precedes the user apply. Never run chezmoi as root or let it manage application runtime data.
- Keep project SDKs, builds and domain skills in their own repositories. Add a workstation language-server override only after a representative project proves it necessary.
- Do not run Windows resources from Nix activation. The owner runs the two Administrator scripts in `windows/`, which are the only elevated operations.
- Korolev's OpenSSH server listens only on tailnet addresses and accepts only keys. Keep local Administrator and Mac recovery access while changing networking.
- Do not install Nix inside CrossOver bottles. Activation may install CrossOver and create an empty bottle, but must not sign in to Steam, update games, install loaders, deploy mods, launch games or delete bottle data.
- The borrowed Air is temporary and must not become a builder, storage, authentication or release dependency. [Issue #17](https://github.com/glockyco/nix-config/issues/17) tracks its removal.

## Before merging

Run the README checks for every platform a change touches. A Windows change also needs the engine's dry run and `chezmoi apply` on Korolev from the PR branch. An OMP or plugin change needs a fresh session in Tern. Keep previous generations until the checks pass. Do not add another updater or scheduler, and keep Nix dependency updates review-only.
