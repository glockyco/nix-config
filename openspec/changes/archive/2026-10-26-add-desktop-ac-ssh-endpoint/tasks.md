# Tasks

## 1. Endpoint

- [x] 1.1 Configure the machine's in-box OpenSSH Server with the Mac's key, SID-based authorization-file ACLs, password and keyboard-interactive authentication off, Windows PowerShell as default shell and the broad port-22 rule disabled. Verify with `sshd -T`, the file's ACL and a refused LAN connection.
- [x] 1.2 Declare the endpoint, pin and check, and document the server and the Tern tunnel. Verify that `nix flake check` passes and that the rendered config pins `SHA256:jYEG4vrFrvlRDuZqxFPbq1NCGcM1LIWNUGtMhv5lR94`.
- [x] 1.3 Apply chezmoi on the Mac. Verify that `ssh desktop-ac-batch 'exit 23'` returns 23 through the installed config, that a password-only attempt is denied, and that `ssh desktop-ac` opens Windows PowerShell.
