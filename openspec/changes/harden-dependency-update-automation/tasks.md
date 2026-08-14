## 1. Authenticate dependency updates

- [x] 1.1 Mint a short-lived GitHub App token in the weekly update workflow
- [x] 1.2 Pass the installation token to the official flake updater
- [x] 1.3 Preserve complete lock updates and manual dispatch

## 2. Add Renovate ownership

- [x] 2.1 Add the shared Renovate configuration
- [x] 2.2 Disable Renovate's beta Nix manager explicitly
- [ ] 2.3 Verify GitHub Actions are detected without duplicate flake ownership

## 3. Strengthen package checks

- [x] 3.1 Expose the selected OpenSpec package in the workstation package set
- [x] 3.2 Compare OpenSpec executable and package metadata versions
- [x] 3.3 Add a pure generated-adapter freshness check
- [x] 3.4 Reject incomplete archived OpenSpec changes
- [x] 3.5 Retain wrapper-shape and Herdr reconciliation checks

## 4. Make operations discoverable

- [x] 4.1 Add a concise root `AGENTS.md`
- [x] 4.2 Add the canonical dependency-update runbook
- [x] 4.3 Document ownership, schedule, commands, checks, activation, smoke, and rollback
- [x] 4.4 Link automation comments and architecture guidance to the runbook
- [x] 4.5 Classify and track every existing planning document

## 5. Verify local contracts

- [x] 5.1 Run repository formatting and complete flake checks
- [x] 5.2 Build the configured Darwin system
- [x] 5.3 Activate and inspect the verified workstation generation
- [x] 5.4 Prove mutable OMP state remains writable and unchanged

## 6. Enforce remote policy

- [x] 6.1 Store the updater App client ID and private key as Actions configuration
- [ ] 6.2 Require the actual Darwin and Linux status contexts
- [ ] 6.3 Require current pull requests and linear history for every actor
- [ ] 6.4 Prevent force-push and branch deletion
- [ ] 6.5 Prove a failing required check blocks merge
- [ ] 6.6 Prove an updater pull request starts both CI jobs automatically

## 7. Complete the change

- [ ] 7.1 Validate the OpenSpec change strictly
- [ ] 7.2 Publish the reviewed implementation through a pull request
- [ ] 7.3 Archive and validate the completed OpenSpec change
