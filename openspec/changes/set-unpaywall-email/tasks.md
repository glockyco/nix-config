# Tasks

## 1. Shared contact and Mac delivery

- [ ] 1.1 Add the single contact declaration under `portable.research.unpaywallEmail` in `home/.chezmoidata/portable.toml` and export it from the Darwin branch of `home/dot_zshenv.tmpl`. Verify both hosts read the same source and a changed fixture contact updates the rendered Mac export without another literal edit.
- [ ] 1.2 Extend existing chezmoi fixtures to check the Mac export, shell-safe quoting, non-interactive zsh inheritance and Windows platform exclusion. Run the relevant fixture checks and confirm Windows gains no zsh destination or PowerShell profile assignment.
- [ ] 1.3 Update existing Mac operational guidance in place to explain applying the user environment and checking it from a fresh Tern OMP session. Verify guidance points to the declaration instead of repeating the address and does not claim a system rollback restores user files.

## 2. Windows persistent environment convergence

- [ ] 2.1 Extend the workstation JSON declaration, schema and invariants with a typed user-environment resource that references the shared contact. Resolve the raw TOML once with the existing chezmoi parser from the engine's checkout before any mutation. Add tests proving direct dry run and apply use that checkout rather than ambient chezmoi data, and that missing reader, invalid TOML, missing or empty contact and unsupported references fail before writes.
- [ ] 2.2 Implement current-user literal-string comparison, changed-only persistence, environment notification and postcondition verification through the existing engine. Add mocked tests for absent, wrong-type, differing and matching values, no-write dry run, existing manual-value adoption, repeated-apply idempotence, rejected elevation, failed writes and failed postconditions. Verify Path, machine environment and unrelated user values remain unchanged.
- [ ] 2.3 Add shared TOML to the existing engine hook's hashed inputs. Extend rendered-hook and checkout fixtures to prove a changed contact reruns the onchange operation, a source edit after rendering is rejected, and both dry run and chezmoi apply resolve the same value. Verify rendered hooks parse under PowerShell 7.
- [ ] 2.4 Update the existing Korolev operations guide in place with persistent user-environment ownership, preview/apply, fresh Tern inheritance checks and explicit recovery of this value only. Verify the documented dry-run command needs no email argument and no address is copied into documentation.

## 3. Platform and integration gates

- [ ] 3.1 On macOS, run README checks sequentially: `nix fmt -- --fail-on-change`, `openspec validate --all --strict`, `openspec validate --archived --strict`, `nix flake check --print-build-logs`, `nix run .#check-darwin-build-plans` and `nix build .#darwinConfigurations.macbook-pro.system`. Record results in the change record and retain previous generations.
- [ ] 3.2 On native Windows, follow README prerequisites and run `pwsh -NoProfile -File .\windows\dev\bootstrap.ps1 -IncludeTestDependencies`, `pwsh -NoProfile -File .\windows\dev\engine-dependencies.ps1`, `pwsh -NoProfile -File .\windows\dev\format.ps1 -Check` and `pwsh -NoProfile -File .\windows\dev\ci.ps1`. Record actual results and confirm mocked checks do not mutate workstation state.
- [ ] 3.3 Review the complete implementation diff and chezmoi previews. Verify this change removes no existing application, unrelated configuration, environment value or runtime state and leaves OMP/plugin/Tern installation and configuration untouched. Run `openspec validate set-unpaywall-email --strict`.
- [ ] 3.4 On Korolev, have the integrator record the pre-apply contact state, run `pwsh -NoProfile -File .\windows\workstation.ps1 -DryRun` from the reviewed PR branch, review every named difference and run ordinary-user `chezmoi apply`. Verify post-apply engine dry run exits zero, `chezmoi verify --exclude=scripts` succeeds, and a repeated apply makes no unexpected changes or contact write/notification. Do not delete the existing manual value first.
- [ ] 3.5 On macbook-pro, perform the authorized system-switch-before-user-apply workflow in an interactive terminal if activation is needed. Run ordinary-user `chezmoi apply`, `chezmoi verify` and a repeated apply. Verify convergence without unexpected writes and keep the prior generation until acceptance passes.
- [ ] 3.6 Start a fresh OMP session in a Tern pane on each host after apply. On Windows, refresh Tern normally if its daemon still has the old environment, preserving running work first. Have OMP run a child command without assigning the contact inline: `printenv UNPAYWALL_EMAIL` on the Mac and `pwsh -NoProfile -Command '[Environment]::GetEnvironmentVariable("UNPAYWALL_EMAIL")'` on Windows. Verify both print exactly the shared declaration and record the observed output in this change. Do not substitute a registry read or a separate interactive shell for this consumer check.

## Workflow follow-up

- Request review after every implementation and live acceptance gate passes. Do not merge or publish without explicit approval.
- Archive only after all tracked tasks are complete and the change validates strictly.
