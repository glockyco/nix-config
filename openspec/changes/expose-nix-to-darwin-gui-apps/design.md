## Context

`modules/home/shell.nix` adds the Home Manager profile to interactive zsh only. Fork inherits the macOS user launchd environment instead. The plugin's pre-push hook calls bare `nix develop`; its checks never start if GUI `PATH` cannot find Nix.

## Goals / Non-Goals

**Goals:** Persist one host-owned GUI command lookup path across reboot. Preserve pinned project tools inside each repository's development shell.

**Non-Goals:** Rewrite hooks across repositories, change Korolev, install project tools globally, or bypass hook failures.

## Decisions

Configure the persistent user-domain path through `launchctl config user path` in the Darwin activation script. Include `/usr/bin`, `/bin`, `/usr/sbin`, `/sbin`, and `/nix/var/nix/profiles/default/bin`. Put Nix last so system commands retain their precedence. Determinate Nix installs `nix` at that stable profile path.

The nix-darwin `launchd.user.envVariables.PATH` option calls `launchctl setenv` during activation only. The pinned boot service does not run user-launchd activation, so that option loses the value after a reboot. `launchctl config user path` is the macOS persistent user-domain setting; it takes effect after reboot. Evaluate the generated activation command and exercise Nix with its proposed `PATH`, without changing live launchd state before review.

The persistent setting affects all Mac users and is stored outside a Nix generation. A rollback to a generation without this activation command does not revert it. Rollback therefore also requires `sudo launchctl config user path '<recorded-prior-path>'` and a reboot. Do not infer or erase another administrator's prior persistent value; record it before activation. If the prior value cannot be established, do not activate this change.

## Risks / Trade-offs

- The persistent value takes effect only after reboot. Check the value inherited by Fork after reboot; `launchctl getenv PATH` during the old session is not proof.
- The fixed GUI `PATH` replaces any prior persistent user-domain value. Record that value before activation, or stop if it cannot be established; retain a restoration command for rollback.
- The value is for all Mac user domains, not the shell's dynamic path. Keep only system paths and the stable Nix bootstrap path; retain project tooling in `nix develop`.
- Until activation and reboot are authorized, checks prove the generated command and simulated lookup, not the live Fork process.
