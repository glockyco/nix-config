# Evidence

Korolev was activated from `fbbc64b` (merged through PR #57) on 2026-10-07.

## Activation

- Before the spike's units were stopped, no process held a file below `/mnt/s`. `sudo systemctl stop mnt-s.automount mnt-s.mount`, removal of the spike's `/run/systemd/system/mnt-s.*` copies, and `sudo systemctl daemon-reload` left no unit behind: `systemctl cat mnt-s.mount` reported `No files found for mnt-s.mount`.
- `sudo nixos-rebuild switch --flake .#korolev` activated generation 50 with configuration revision `fbbc64b1e4e132631900fe7a3f9800c9869b87c5` and reported `the following new units were started: mnt-s.automount`. Generation 49 (`16cd535`) remains. `nix store diff-closures` against generation 49 reported only `unit-mnt-s.mount: ∅ → ε`.
- `/mnt/s` was unavailable for 4.9 s, from stopping the spike's units until the new automount was active.
- `systemctl show mnt-s.mount` reported `FragmentPath=/run/systemd/generator/mnt-s.mount`, `SourcePath=/etc/fstab`, the drop-in `mnt-s.mount.d/overrides.conf` from the system units, and `StartLimitIntervalUSec=0`.
- `verify-personal-omp` reported OMP 18.6.1, the plugin at `/nix/store/bcp53cccjpazkv7wlj7wwhbkzbks2a12-personal-omp-plugin-0.1.0`, and `omp: current`.

## Reachable share

- Before the first access, `/mnt/s` held only the `autofs` mount. Listing `/mnt/s/BigDataOrion/sea` succeeded in 350 ms and mounted `\\scch.at\SCCH` as `9p` with the options `ro`, `uid=1000`, and `gid=100`.
- The listing matched `Get-ChildItem -Force -Name 'S:\BigDataOrion\sea'` from Windows PowerShell: both contain only `saner2027-paper`.
- The directory, its entry, and the entry's `cache` and `output` subdirectories belong to `user:users` (1000:100).
- `touch` and `mkdir` below `/mnt/s/BigDataOrion/sea` failed with `Read-only file system`. The Windows listing was unchanged afterwards.
- `systemctl is-system-running` reported `running`, and no unit had failed.

## Unreachable share

2026-10-07, VPN disconnected, after `sudo systemctl stop mnt-s.mount` unmounted the share while `mnt-s.automount` stayed active. Five consecutive `ls /mnt/s` calls each failed with exit 2 (`No such device`; the mount unit logged `fsconfig() failed: Host is down.`) in 639, 585, 603, 644 and 697 ms. `mnt-s.automount` remained `active` and nothing was mounted. After the owner reconnected the VPN, the next `ls /mnt/s` succeeded in 1133 ms and mounted the share.
