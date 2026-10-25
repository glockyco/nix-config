## Why

Korolev selects the GitHub no-reply address only for worktrees below `~/src/github.com/`. On 2026-10-25, agents worked on glockyco repositories in scratch clones outside that tree, and 50 commits in 27 GitHub repositories carried the SCCH address until their history was rewritten. The change `broaden-github-git-identity` had accepted this case as a risk. Selecting the identity by the repository's remote follows the repository instead of the directory it sits in.

## What Changes

- Apply `11704293+glockyco@users.noreply.github.com` to every Korolev repository with a remote on github.com, over HTTPS or SSH, wherever the repository lives.
- Keep the existing `~/src/github.com/` condition for repositories in that tree without a GitHub remote, such as a new repository before its first push.
- Keep `johann.glock@scch.at` as the global email for every other repository, including gitlab.scch.at repositories outside the GitHub tree.
- Preserve repository-local `user.email` overrides.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `windows-workstation-layer`: Korolev's Git identity selection also follows the repository remote.

## Impact

- Affects the Windows section of `home/dot_gitconfig.tmpl` and the identity fixture in `windows/tests/chezmoi-core.ps1`.
- Needs Git 2.36 or later for `hasconfig:remote.*.url` conditions. The Mac and its identity are unchanged.
