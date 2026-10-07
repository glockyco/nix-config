## 1. Declare the share

- [x] 1.1 In `hosts/korolev/`, declare `fileSystems."/mnt/s"` for `\\scch.at\SCCH` with `fsType = "drvfs"` and the options `ro`, `noauto`, `x-systemd.automount`, and `nofail`. Take the uid and gid from the declared interactive user and group. Comment why the UNC path is used rather than the drive letter. Verify that the evaluated Korolev configuration shows this device, type, and option list.
- [x] 1.2 Disable the start limit of `mnt-s.mount` through a drop-in on the fstab-generated unit (`overrideStrategy = "asDropin"`), with a comment on the empty-directory failure it prevents. Verify that the built drop-in contains only `[Unit]` and `StartLimitIntervalSec=0`, and that no full `mnt-s.mount` definition competes with the generated one.
- [x] 1.3 Assert the device, the read-only and automount options, and the start-limit drop-in in Korolev's evaluation checks in `flake-modules/checks.nix`. Verify that the check fails when the `ro` option or the drop-in is removed.
- [x] 1.4 Document `/mnt/s` in the README's network section: the source, read-only access, and behavior when the share is unreachable. Verify that the README's statements match the declaration.

## 2. Validate and activate

- [x] 2.1 Validate the change with `openspec validate mount-scch-share-on-wsl-host --strict` and run the README gates `nix fmt -- --fail-on-change` and `nix flake check --print-build-logs`.
- [x] 2.2 Review and commit. Remove the spike's transient units with `sudo systemctl stop mnt-s.automount mnt-s.mount`, `sudo rm -r /run/systemd/system/mnt-s.*`, and `sudo systemctl daemon-reload`, and verify that `systemctl cat mnt-s.mount` finds no unit. Then activate the committed Korolev configuration under the README release procedure, keeping the previous generation.
- [x] 2.3 Check the reachable case on the activated host. Listing `/mnt/s/BigDataOrion/sea` mounts the share with `ro`. The entries match `S:\BigDataOrion\sea` and belong to the interactive user. Creating a file fails. `systemctl is-system-running` reports `running`.
- [x] 2.4 Check the unreachable case. With the VPN disconnected and the share unmounted, five consecutive listings of `/mnt/s` each fail and `mnt-s.automount` stays active. After reconnecting, the next listing succeeds. Record the observed latencies in this change.
