# Tasks

## 1. Configuration and documentation

- [x] 1.1 Add `omp config set memory.backend off` to the README's OMP block and the Korolev runbook, with the reason in the README.
- [x] 1.2 Drop the porting of memory banks from the workstation spec and add the requirement for memory off.
- [x] 1.3 Run the formatter, both OpenSpec validations and `nix flake check`. Verify that they pass.

## 2. Hosts

- [x] 2.1 Set the option on the Mac and Korolev. Verify that a fresh session in `/tmp` on the Mac and in `%TEMP%` on Korolev carries no line of its folder's bank, and that the same session with memory on quotes it.
