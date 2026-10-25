## 1. Identity Policy

- [x] 1.1 Add `hasconfig:remote.*.url` includes for `https://github.com/**`, `git@github.com:*/**` and `ssh://git@github.com/**` to the Windows section of `home/dot_gitconfig.tmpl`, keeping the `~/src/github.com/` path include.
- [x] 1.2 Extend the identity fixture in `windows/tests/chezmoi-core.ps1` with repositories outside the GitHub tree that have GitHub remotes in each URL form and one with a gitlab.scch.at remote.

## 2. Verification and Deployment

- [x] 2.1 Run the Windows checks from the README and validate this change with `openspec validate select-github-identity-by-remote --strict`.
- [x] 2.2 Run the engine dry run and `chezmoi apply` on Korolev from the branch, then verify the effective email in a GitHub clone outside the GitHub tree, in a repository below `~/src/github.com/` and in an SCCH GitLab repository.
- [x] 2.3 After merge, mark every completed task and archive the change.
