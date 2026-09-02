# Acceptance baseline

Recorded before the first edit, on `x86_64-linux`, with a clean tracked worktree.

| Item                                    | Value                                                                     |
| --------------------------------------- | ------------------------------------------------------------------------- |
| `HEAD`                                  | `3d58d2ee15605066b2c2b680ac15eef64be6a38d`                                |
| `flake.lock` SHA-256                    | `56bb25b6e102b743aa000896c5be167d30dce44cfb4a4ea8522f1107051ef4fa`        |
| Gate A: Darwin system, revision pinned  | `/nix/store/sjdxm34sg1c5cvm63c586p9akvx07ksm-darwin-system-26.05.c3e90c8` |
| Gate B: Home Manager activation package | `/nix/store/y9c6x2lsbvh374yppizpqpbdhxnwb2pb-home-manager-generation`     |

## Gate A

```sh
nix eval --raw '.#darwinConfigurations.macbook-pro' \
  --apply 'c: (c.extendModules { modules = [ ({ lib, ... }: { system.configurationRevision = lib.mkForce "gate"; }) ]; }).system.outPath'
```

The pin is required. `modules/darwin/system.nix` sets `system.configurationRevision` from the flake revision, and that value enters the system derivation. A probe confirmed that one appended newline in a tracked file changes the unpinned path:

| Tree state        | Revision                                         | Unpinned system path                                                      |
| ----------------- | ------------------------------------------------ | ------------------------------------------------------------------------- |
| clean             | `3d58d2ee15605066b2c2b680ac15eef64be6a38d`       | `/nix/store/inp9an8xw0c5bl1gr9vlllksxr7kx6p6-darwin-system-26.05.c3e90c8` |
| one newline added | `3d58d2ee15605066b2c2b680ac15eef64be6a38d-dirty` | `/nix/store/lb2hpa3k5fkpqida76qnl2hx633z180k-darwin-system-26.05.c3e90c8` |

Both gates returned an identical path in the clean state and in that dirty state, so both are independent of the tree state.

## Gate B

```sh
nix eval --raw '.#darwinConfigurations.macbook-pro.config.home-manager.users.glockyco.home.activationPackage.outPath'
```

Gate B is the tighter gate, because every edit in this change reaches the user scope. Gate A detects an accidental change in system scope.

## Rule

`flake.lock` SHALL NOT change while this change is open. An input update moves both paths and invalidates the comparison.
