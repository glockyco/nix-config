## 1. Wrapper routing

- [x] 1.1 Add WSL-only leading `update` dispatch to `packages/personal-omp.nix`; verify the built wrapper selects the fixed standalone target without session plugin flags.

- [x] 1.2 Add observable regression coverage to the existing wrapper checks; verify update arguments and failing exit status, missing-executable rejection, normal and nested command resolution, and unchanged Darwin routing.

- [ ] 1.3 Extend leading `update` routing to Darwin through the official Homebrew formula prefix; verify failed prefix resolution stops without fallback and normal sessions remain wrapped.

- [ ] 1.4 Update routing regression coverage for both platforms; verify Darwin preserves arguments and exit status without session flags and does not expose the update path to normal sessions.

## 2. Runtime acceptance

- [x] 2.1 Perform a real WSL binary update through the built wrapper; record initial and final versions, the updated path, and successful `verify-personal-omp` output in change evidence.

- [x] 2.2 Run the disposable wrapped-session smoke and `personal_commit` preview; record the immutable plugin path, active policy, and unchanged disposable repository.

- [x] 2.3 Run the managed-browser smoke through the candidate wrapped session; record the Example Domain title and screenshot without loader errors.

- [ ] 2.4 Run a real native Darwin update through the candidate wrapper; record Homebrew delegation, initial and final versions, and successful `verify-personal-omp` output.

- [ ] 2.5 Run the native Darwin wrapped-session smoke and exact personal commit preview; record the immutable plugin path, active policy, and unchanged disposable repository.

## 3. Documentation and release

- [ ] 3.1 Update README routine guidance to `omp update` on both platforms; verify bootstrap and pinned recovery retain the owning platform installer.
- [ ] 3.2 Run `openspec validate route-omp-self-update --strict` and all README release gates, including native platform checks; record each result with this change.
- [ ] 3.3 After review and rebase integration, activate both committed host configurations and inspect output; verify plain `omp update --check` from each default shell and repeat the required activation smoke before acceptance.
