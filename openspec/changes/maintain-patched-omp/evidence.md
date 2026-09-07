# Verification evidence

## Shared patch source — 2026-09-07

Published the user-approved branch `fix/wsl-terminal-hyperlinks` to `https://github.com/glockyco/oh-my-pi` without changing the upstream repository.

- Upstream base: `a1b254047d12e143b7c6011536e918c6c35c5906`.
- Patch tip: `62aa62869813e2834dc5887453f0f6c984953442`.
- Korolev and macbook-pro each fetched the branch into a new, separate temporary bare repository.
- On each host, `git merge-base --is-ancestor <base> <tip>` succeeded and `git rev-list --count <base>..<tip>` returned `5`.
- Upstream's latest-release API reported `v18.1.13`, with `draft=false` and `prerelease=false`.

## Implementation verification — 2026-09-07

- `openspec validate maintain-patched-omp --strict`: passed.
- `nix fmt -- --fail-on-change` and `nix flake check --all-systems --print-build-logs`: passed.
- The updater's 16 behavioral tests and the wrapper shape, generation, and verifier checks passed on both architectures. Darwin checks ran on macbook-pro through the existing builder connection.
- The Darwin system built successfully. The native `check-darwin-build-plans` command checked 37 outputs and found no forbidden source build.
- Korolev completed source preparation and selected `generations/v18.1.13-tnmqfjfj`, with result commit equal to the pinned patch tip. All three package checks, 361 regressions across ten files, native loading, and immutable plugin registration passed. The packaged wrapper reported `18.1.13` from `/tmp`.
- An initial native-load probe omitted the raw binding's required tab-width argument. Preparation failed without selecting that candidate. The corrected probe and a complete subsequent preparation passed. A concurrent rollback attempt was rejected while preparation held the lock.

## Update and recovery verification

The latest stable tag remained `v18.1.13`. Each host prepared a temporary local mirror with the same five patches and different commit identities. `git diff --exit-code` proved that its source tree matched the published tip. This supplied a changed input for a real, fully checked native update without publishing verification commits.

On both hosts, an unavailable patch input left `current` and `previous` unchanged. Rollback succeeded with the GitHub client disabled and both remote paths unavailable. A subsequent default update returned unchanged without creating another generation. Both hosts ended on the canonical published patch tip. Temporary mirrors, fault-injection configurations, fetch probes, and failed candidates were removed; current and previous verified generations remain.

## Korolev acceptance

Activated implementation commit `0e0d30cad34d40b1da5ad9c74ec21953a060f3f4` with `sudo nixos-rebuild switch --flake .#korolev`. Activation succeeded, and the Home Manager log showed Herdr reconciliation without source preparation.

- A fresh login shell resolved `omp` and `omp-dev-update` through `/etc/profiles/per-user/user/bin`.
- `verify-personal-omp` reported the canonical commit, version `18.1.13`, immutable plugin `/nix/store/x2bq1ds306bni8y869w5gdcfk2g0zj19-personal-omp-plugin-0.1.0`, and `omp: current (v8)`.
- A fresh Herdr tab recognized the activated source OMP as ready. Its model-backed smoke reported the immutable plugin path and personal commit policy, then completed the required `personal_commit` preview. The disposable repository remained empty, unstaged, and without a commit.
- The same session opened `https://example.com` in the managed browser, reported `Example Domain`, captured the [verified screenshot](browser-smoke.webp), and closed the browser. The temporary Herdr tab was closed afterward.
- The activated `omp acp` completed a newline-framed JSON-RPC initialization with protocol version `1` and agent version `18.1.13`; the smoke process was stopped.

## Mac runtime verification

The Mac independently selected `generations/v18.1.13-tqkiqh1m` at the canonical patch tip. All three package checks, 361 regressions across ten files, native loading, and immutable plugin registration passed. The packaged source verifier reported version `18.1.13`, plugin `/nix/store/h6mjqcm3rpsj9pdxzn07n9rjbn84f132-personal-omp-plugin-0.1.0`, and `omp: current (v8)`.

A private Git bundle transferred the committed implementation to the Mac without pushing `nix-config` or changing its existing checkout. A complete native `nix flake check` passed from that review checkout, including the Darwin system build.

## Remaining operator gate

The Mac's installed Nix is Determinate Nix 3.21.9 / Nix 2.34.8. Remote `sudo -n true` requires a password. No privilege or authentication configuration was changed. From a Mac terminal, activate the retained review checkout:

```sh
cd ~/.local/share/nix-config-review/maintain-patched-omp-0e0d30c/checkout
sudo nix run .#darwin-rebuild -- switch --flake .#macbook-pro
verify-personal-omp
```

Task 4.3 still requires activation output review and the fresh wrapped-session smoke in Herdr. Task 4.4 remains blocked by that gate. The temporary Korolev launcher, developer checkout, previous Nix generations, and installer-owned files remain intact.
