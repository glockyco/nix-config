## 1. Wrapper routing

- [ ] 1.1 Add WSL-only leading `update` dispatch to `packages/personal-omp.nix`; verify the built wrapper selects the fixed standalone target without session plugin flags.
- [ ] 1.2 Add observable regression coverage to the existing wrapper checks; verify update arguments and failing exit status, missing-executable rejection, normal and nested command resolution, and unchanged Darwin routing.

## 2. Runtime acceptance

- [ ] 2.1 Perform a real WSL binary update through the built wrapper; record initial and final versions, the updated path, and successful `verify-personal-omp` output in change evidence.
- [ ] 2.2 Run the disposable wrapped-session smoke and `personal_commit` preview; record the immutable plugin path, active policy, and unchanged disposable repository.
- [ ] 2.3 Run the managed-browser smoke through the candidate wrapped session; record the Example Domain title and screenshot without loader errors.

## 3. Documentation and release

- [ ] 3.1 Update README routine WSL guidance to `omp update`; verify bootstrap and pinned recovery still use the official installer and Darwin retains Homebrew.
- [ ] 3.2 Run `openspec validate route-omp-self-update --strict` and all README release gates, including native platform checks; record each result with this change.
- [ ] 3.3 After review and merge, activate the committed WSL configuration and inspect output; verify plain `omp update --check` from the default shell and repeat the required activation smoke before acceptance.
