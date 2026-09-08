## Context

See `proposal.md` for motivation. The existing workflow installs Determinate Nix on two native runners and uses the configured Numtide binary cache. It does not retain our downstream-built store outputs between jobs. Repository secrets contain Tailscale authorization only; no cache-provider credential is configured.

The central controller runs a complete `nix flake update` and may change only declared paths, including this repository's `flake.lock`. There is no target-local update workflow. Both wrapper compositions currently select Plannotator from the same rolling `llm-agents` package set used for other tools.

## Goals / Non-Goals

**Goals:** Make Plannotator release advancement deliberate. Reuse its actual derived output across fresh CI runners. Preserve the existing package recipe and complete validation gates.

**Non-Goals:** A second scheduler, an updater script, an external cache account, a host binary-cache service, a frozen workstation toolchain, or weaker release acceptance.

## Decisions

### Declare an immutable package-source input

Add `plannotator-packages` as another instance of `github:numtide/llm-agents.nix`, with the reviewed full commit in the declared URL. Initially use the currently verified source revision. Preserve the vendor's own locked transitive inputs. The existing declaration explicitly forbids following workstation `nixpkgs`, because the vendor requires its pinned unstable package set and cache.

Select only Plannotator from this package set in both compositions. Continue to append the downstream patch through `packages/plannotator.nix`. Other tools retain their existing `llm-agents` input.

An explicit Plannotator update changes the declared revision in `flake.nix`, then updates `plannotator-packages` in the lock. A complete automatic lock update cannot advance that declared commit. Its vendor toolchain stays locked too; unrelated workstation inputs can still advance. Verify this with the actual central updater command in a disposable checkout, not a source-text assertion.

Do not add an updater exclusion or special case to the controller. A floating second input would not solve the problem: the complete update would advance it too. Copying the vendor package recipe would introduce another maintenance owner.

### Cache derived outputs in existing GitHub CI

Use the maintained `nix-community/cache-nix-action`, pinned to a reviewed commit. Its documented supported installers include the existing Determinate action, on Linux and macOS. Use separate restore and save phases so only a successful required-check run publishes a new cache.

Derive the primary key from the native Nix system, a cache-layout version, and the evaluated patched Plannotator derivation identity. Do not key solely on its human-readable version or the whole flake lock. Package source, patch, and toolchain changes must invalidate the identity; unrelated lock changes need not do so.

After restore, run the existing Darwin build-plan guard on macOS. Then build Plannotator with a job-local output link before the flake checks. This keeps its closure rooted during cache garbage collection. Cache hits still run the ordinary checks and package validation. Use a 2 GiB garbage-collection target per native cache; it is a target, not a guarantee when live roots exceed it. Record actual cache size and adjust within GitHub's repository quota before acceptance. Never run this garbage collection on workstation hosts.

Archive only `/nix/store` and the Nix store database. Exclude installer metadata, which can contain a GitHub token. The action prepends `/nix` to its path input, so exclude that broad root before re-including the store and database directories.

Save only after successful checks. Keep GitHub's normal branch and pull-request cache isolation. Do not use `pull_request_target`, grant new write credentials, import caches from arbitrary repositories, or add a host trusted key. No custom cache purge scheduler or cross-ref cache promotion is proposed.

A missing, evicted, incompatible, or unavailable cache must leave an ordinary source build available. Cache-save failure must not replace a successful check result with a claim of reusable output. Report the cache failure and verify a later hit before accepting the feature.

### Preserve the trust and release boundaries

GitHub Actions cache is a CI optimization, not a binary substituter for the Mac or Korolev. Hosts reuse their existing local store outputs until collection or changed derivations require another build.

Successful PR caches remain PR-scoped. A protected main-branch run must populate a base cache before new PRs can reuse it. Expect initial cold builds on each architecture, including a main-branch population build. Do not promise that the current in-flight release becomes faster.

Native browser, lifecycle, network, rollback, and downstream patch review requirements remain unchanged. Keep this implementation separate from `add-plannotator-visual-feedback` acceptance.

## Risks / Trade-offs

- An unchanged application version can rebuild after a Bun, Nixpkgs, dependency, or patch change. The evaluated derivation, not the version label, is the cache identity.
- GitHub cache quotas and eviction make reuse best-effort. Measure cold and warm runs, transfer sizes, and source-build absence on both systems.
- The cache action merges Nix store databases. Confirm compatibility with the installed Nix and SQLite versions on both actual runners; do not replace the native Nix check client.
- A 2 GiB collection target cannot discard live roots. Retain the package output, inspect size, and avoid accumulating broad fallback caches.
- A new Plannotator update still needs a source build and full behavior verification. On-demand selection reduces unnecessary updates, not required correctness work.

## References

- [Central updater contract](https://github.com/glockyco/dependency-automation)
- [Cache action compatibility, isolation, and limitations](https://github.com/nix-community/cache-nix-action)
