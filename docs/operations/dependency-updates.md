# Updates

| What                              | How it updates                                                                                       |
| --------------------------------- | ---------------------------------------------------------------------------------------------------- |
| Nix inputs                        | [Dependency automation](https://github.com/glockyco/dependency-automation) opens a PR every Saturday |
| GitHub Actions                    | Renovate PRs                                                                                         |
| Markdown Oxide and Roslyn         | By hand in their package declarations, see [pinned artifacts](#pinned-artifacts)                     |
| Plannotator                       | By hand, see [Plannotator](#plannotator)                                                             |
| OpenSpec                          | By hand, see [OpenSpec](#openspec)                                                                   |
| OMP and the personal plugin       | Their own commands, see the [README](../../README.md#omp)                                            |
| Windows applications and TeX Live | See [Korolev Windows](korolev-windows.md#change-or-update-something)                                 |
| The personal desktop's OpenSSH    | By hand, see [Personal desktop](desktop.md#openssh-server-updates)                                   |

No updater merges or activates anything. The dependency automation repository owns manual dispatch, run inspection and App key rotation. This repository holds no App credential. Do not add a second Nix updater or enable Renovate's Nix manager.

## Pinned artifacts

[Markdown Oxide](../../packages/markdown-oxide/package.nix) and [Roslyn](../../packages/roslyn-language-server/package.nix) are pinned release assets. Change the version, the platform asset and the hash together, and never accept changed bytes under an existing hash. If the personal plugin starts selecting a different language server, release the plugin and change the [user package list](../../modules/shared/user-packages.nix) together, without keeping the old server as a fallback.

## OpenSpec

CI validates with the version that omp-agent-setup's [reusable workflow](https://github.com/glockyco/omp-agent-setup/blob/main/.github/workflows/openspec.yml) installs, called at a full commit in [check.yml](../../.github/workflows/check.yml). Windows pins the same version in [windows/npm](../../windows/npm/package.json) for its commit hook. The Mac's CLI comes from the `llm-agents` input and moves with the Nix inputs. After an OpenSpec update, regenerate the adapters and release the plugin in [omp-agent-setup](https://github.com/glockyco/omp-agent-setup#release-flow), then advance the workflow commit and the Windows pin together.

## Plannotator

Plannotator comes from the `plannotator-packages` input in [flake.nix](../../flake.nix), pinned to a full commit, and advances only on request. Keep the vendor's own Nixpkgs selection instead of following this flake's.

1. Review the vendor revision and its Plannotator version.
1. Change the commit in `inputs.plannotator-packages.url` and run `nix flake update plannotator-packages`.
1. Review the URL and the lock diff together, then build and activate.
1. In a fresh OMP session, check `/plannotator-annotate <path>`, `/plannotator-last` and `/plannotator-cancel`.

## After an update

- `omp --version` shows the expected version, and `omp plugin list` shows `personal@glockyco` once, in user scope.
- After an OMP, plugin or Plannotator change, start a fresh session in a disposable repository. The personal policy applies, the `/personal:opsx-*` commands are listed and a `personal_commit` preview leaves the repository unchanged.
- After a language-server change, open a representative project at its root and check diagnostics, definition, references and rename. Roslyn loads projects in the background, so judge its results after loading finishes.
