# Verification Evidence

Verified on Korolev on 2026-09-18.

## Declarative configuration

The evaluated Home Manager Git configuration reported:

```text
globalEmail = johann.glock@scch.at
condition = gitdir:~/src/github.com/
conditionalEmail = 11704293+glockyco@users.noreply.github.com
```

The documented command in the existing GitHub checkout reported:

```text
$ git config user.email
11704293+glockyco@users.noreply.github.com
```

## Repository gates

```text
$ nix fmt -- --fail-on-change
formatted 3 files (0 changed)

$ nix flake check --print-build-logs
running 18 flake checks...
all checks passed!
```

The flake check evaluated and built the Korolev system and Home Manager generation. It also validated the OpenSpec contracts.

## Generated configuration smoke

An isolated temporary home used the generated Home Manager Git configuration. Disposable repositories produced these effective values:

```text
github.com/glockyco/repo       11704293+glockyco@users.noreply.github.com
github.com/another-owner/repo  11704293+glockyco@users.noreply.github.com
gitlab.scch.at/team/repo       johann.glock@scch.at
GitHub repository override     override@example.test
```

The temporary home was removed after verification.

## Activated configuration

The committed configuration was activated with:

```text
$ sudo nixos-rebuild switch --flake .#korolev
Done. The new configuration is /nix/store/3qkqzirxwnq2fv9f46rd5b05vlvqnzxj-nixos-system-korolev-26.05.20260903.a5cc6f2
```

Activation completed successfully. It restarted `home-manager-user.service` and reported no activation error.

Disposable repositories under the live checkout roots produced these effective values:

```text
~/src/github.com/<temporary-owner>/repo    11704293+glockyco@users.noreply.github.com
~/src/gitlab.scch.at/<temporary-group>/repo johann.glock@scch.at
GitHub repository override                  override@example.test
```

All disposable repositories were removed after verification.
