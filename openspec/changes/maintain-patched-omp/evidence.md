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

## Patch refresh for v18.1.14

The local OMP branch `fix/wsl-terminal-hyperlinks-v18.1.14` retains the five fixes on upstream base `daf07999c2fee9b22edc7bf8fea1fb6272e0df5e`. Its tip is `16a6bd10e859ca26a0011ed5ba26d4c260e2b754`.

The refresh resolved the Markdown test import overlap by retaining both required helpers. The other patches applied cleanly. A separate documentation commit moved personal changelog entries back to `Unreleased`, preserving published upstream entries exactly. Excluding changelogs, range comparison showed only the import adjustment relative to the original five patches.

Korolev verification passed: frozen dependency installation, a fresh native build, all three package checks, and 364 regressions across ten files. Native loading and immutable `personal_commit` registration passed. The source launcher reported `18.1.14` outside the checkout with isolated application state. The upstream Nix flake and lockfile were unchanged, so verification used the existing locked development profile.

After explicit approval, the refreshed branch was published to `glockyco/oh-my-pi` without rewriting the original branch. The repository updater pins now reference the verified base and tip above. Both hosts independently fetched that exact range into temporary bare repositories and verified its ancestry: five fix commits plus the changelog correction. Formatting, strict OpenSpec validation, the flake checks, the Darwin OMP checks, and the Darwin system build passed. This pin update does not activate host configuration or change the selected runtime.

## Remaining operator gate

The Mac's installed Nix is Determinate Nix 3.21.9 / Nix 2.34.8. Remote `sudo -n true` requires a password. No privilege or authentication configuration was changed. From a Mac terminal, activate the retained review checkout:

```sh
cd ~/.local/share/nix-config-review/maintain-patched-omp-0e0d30c/checkout
sudo nix run .#darwin-rebuild -- switch --flake .#macbook-pro
verify-personal-omp
```

Task 4.3 still requires activation output review and the fresh wrapped-session smoke in Herdr. Task 4.4 remains blocked by that gate. The temporary Korolev launcher, developer checkout, previous Nix generations, and installer-owned files remain intact.

## Published native components — 2026-09-10

The Mac prepared release `v18.1.16` with the reviewed updater at
`/nix/store/gifhmw4hlgac1vf05zr93yc3n65skjvs-omp-dev-update`. The native phase
reported `installing verified @oh-my-pi/pi-natives-darwin-arm64@18.1.16`,
installed a 164 682 896 byte addon, and created no `target` directory. The
complete update took 2 minutes 9 seconds and passed package checks, ten
regression files, native loading, and the plugin launch check. The selected
generation is `v18.1.16-5krhiv_m` at commit
`1f41d9b679f381837156aae86495fcc56fe7ea41` on upstream
`61b1b8aef634334eaf1412afd003a763e1d1b9c1`.

Verification uses the registry integrity digest and `gh attestation verify`
against `can1357/oh-my-pi`, with predicate `https://slsa.dev/provenance/v1` and
`--digest-alg sha512`. Manual confirmation before implementation showed that the
published tarball digest matches both the packument integrity value and the
provenance subject digest, and that the provenance names the upstream release
workflow.

The persistent cache holds 1.4 GB of Bun packages at
`~/.local/share/omp-dev/cache`. Candidate homes, agent directories, and session
state stayed inside their generations.

Two consecutive `--rollback` operations selected `v18.1.13-tqkiqh1m` and then
`v18.1.16-5krhiv_m` again, without a download or a build. `verify-personal-omp`
reported the matching release, a `/nix/store` plugin path, and `omp: current` in
both states. An earlier interrupted candidate, `v18.1.16-ntd7c1gw`, left the
selection unchanged and retained its diagnostic files.

A fresh wrapped session in a disposable repository loaded the plugin from
`/nix/store/h2d0q2rh5i5c62jq7d25qf7win2x60zj-personal-omp-plugin-0.1.0`, quoted
the commit policy, and returned a `personal_commit` preview that changed no
repository state. `nix fmt -- --fail-on-change`, `nix flake check`,
`check-darwin-build-plans` (37 outputs), and the `macbook-pro` system build all
passed. The 23 updater tests pass in the `personalOmpUpdate` check.

Host activation and the Herdr pane smoke remain operator gates. `HERDR_ENV` is
absent in this session, so the fresh Herdr-managed session smoke was not run.

## Mac acceptance — 2026-09-10

`darwin-switch` activated `darwin-system-26.05.c3e90c8`
(`3334ipi54hml7sn0qygpqzbf1pxhs92b` to
`6kiqcnlfcb739l00113b82bq5zrl7cri`). The closure grew by one path,
`nss-cacert 3.126`, which supplies the certificate bundle that the updater now
pins. The previous system generation remains available. The profile command
resolves to `/nix/store/j08m5f93biyzlmjnw0frkq1japwpmc9y-omp-dev-update`. A
following `omp-dev-update` reported `unchanged` in 2.4 seconds and created no
candidate.

A fresh wrapped session started through Herdr as agent `smoke` in pane `wG:p2`,
in a disposable repository. It reported OMP `18.1.16`, the plugin path
`/nix/store/h2d0q2rh5i5c62jq7d25qf7win2x60zj-personal-omp-plugin-0.1.0`, and the
first commit-policy rule verbatim. Its `personal_commit` preview returned the
formatted message and left the repository at one commit with a clean status. The
pane created for this check was closed afterward.

Two obsolete generations were removed after the acceptance run:
`v18.1.16-ntd7c1gw`, an interrupted candidate, and `v18.1.13-2_z6cmjt`, an
unlinked older generation. Their worktree registrations were pruned. The
selected generation and the retained previous generation were not changed.
