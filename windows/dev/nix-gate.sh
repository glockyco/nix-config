#!/usr/bin/env bash
set -euo pipefail
# wsl.exe --exec supplies an FHS PATH, not the NixOS login environment.
# Use the activated host commands and its declared WSL extraBin bridge only;
# do not inherit arbitrary Windows/user executables for Git or coreutils.
export PATH=/run/current-system/sw/bin:/bin
expected_root=$1
proof_file=$2
proof_value=$3
cd -- "$expected_root"
actual_root=$(git rev-parse --show-toplevel)
if [[ $(realpath -- "$actual_root") != $(realpath -- "$expected_root") ]] || [[ $(cat -- "$proof_file") != "$proof_value" ]]; then
  printf '%s\n' 'Wrong checkout: WSL must validate the exact native Git checkout, not the Linux clone.' >&2
  exit 1
fi
host_nix=/run/current-system/sw/bin/nix
if [[ ! -x $host_nix ]]; then
  printf '%s\n' 'Missing declared Korolev Nix environment in WSL; activate the reviewed NixOS generation before committing .nix files.' >&2
  exit 1
fi
# Resolve the checkout's exact host implementation with the trusted installed
# Nix, just like Linux CI; never select an arbitrary executable from PATH.
pinned_nix=$($host_nix build '.#nixosConfigurations.korolev.config.nix.package^out' --no-link --print-out-paths)
# Full-tree checking avoids transferring filenames through another shell and
# retains the same pinned wrapper used by the Darwin/Linux commit gate. Do not
# enter the Unix dev shell here: its hook installation would replace Windows'
# fail-closed native launcher on this shared checkout.
exec "$pinned_nix/bin/nix" fmt -- --fail-on-change
