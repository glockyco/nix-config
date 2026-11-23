# Tasks

## 1. Declaration

- [x] 1.1 Add `portable.research.unpaywallEmail` and export it in the Darwin branch of `home/dot_zshenv.tmpl`. Verify with the render check that every zsh kind prints the declared address.
- [x] 1.2 Declare the registry setting for `HKCU:\Environment` in `windows/workstation.json`, with a declaration test that compares it to the shared value. Verify that the test passes and fails on a changed value.

## 2. Checks

- [ ] 2.1 Run the README checks on the Mac and on Windows and strict validation of this change. Verify that all pass.

## 3. Hosts

- [ ] 3.1 On Korolev, run the engine dry run and `chezmoi apply` from the pull request branch. Verify that a fresh Tern session prints the address.
- [ ] 3.2 On the Mac, apply the user files. Verify that a fresh Tern session and `ssh macbook-pro-batch 'printenv UNPAYWALL_EMAIL'` print the address.

## Workflow follow-up

- Archive the change with its accepted specs after the host checks pass.
