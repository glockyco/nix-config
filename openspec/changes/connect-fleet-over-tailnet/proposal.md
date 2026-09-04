## Why

Cross-platform verification runs by hand today. A Darwin gate runs on the Mac, a Linux gate runs on `korolev`, and a change that touches both systems waits for the operator to move between machines. The measured network state on 2026-09-04 explains why nothing else was possible: `korolev` is a WSL 2 distribution in NAT mode behind the Windows resolver at `10.255.255.254`, Windows resolves `macbook-pro.local` by mDNS, `korolev` does not, and the Mac has Remote Login off. The two hosts have no addressable path to each other, and the Air is reachable only while the Mac is on the same LAN, through the `.local` literal in `modules/home/darwin/ssh.nix:12` and `modules/home/darwin/network-shares.nix:9`.

Nix has a native answer to cross-system verification: a remote builder. With the Mac declared as an `aarch64-darwin` builder, `nix build .#checks.aarch64-darwin.darwinSystem` and `nix flake check --all-systems` from `korolev` evaluate locally and build on the Mac. What is missing is a network on which the machines can name and reach each other regardless of location, an SSH path to the Mac that does not put a private key on the work machine, and an access policy that keeps `korolev` unreachable from every other machine.

The owner has decided that `korolev` may hold a device identity for this network and may act as a client of the Mac. This reverses the 2026-09-03 decision that `korolev` holds no shared secret and drives no other host. The employer endpoint-monitoring concern that motivated that decision is recorded and accepted.

The Air is a borrowed research machine. It remains available for a few months so the owner can retrieve and inspect PhD thesis and TOSEM paper results. It is a temporary peer, not a durable fleet host, builder, storage authority, or authentication dependency.

## What Changes

- Join the three durable machines and the temporary Air peer to one Tailscale tailnet as tagged nodes: `tag:macbook-pro`, `tag:korolev`, `tag:desktop`, and `tag:air`. MagicDNS names replace every `.local` name. The Air peer declaration records its temporary lifecycle and research-results purpose.
- Declare the tailnet policy as Nix data and render it as a package. Grants allow every node to reach the Mac, the Air, and the desktop, and allow `korolev` to reach all three. No grant names `korolev` as a destination. Evaluation asserts that invariant, and the policy carries Tailscale `tests` and `sshTests` that assert it again at apply time.
- Apply the rendered policy through Tailscale's GitOps action: `test` on pull requests, `apply` on `main`, authenticated with a federated identity so the repository stores no long-lived credential. The policy contains no e-mail address, because this repository is public.
- Run Tailscale SSH on the Mac through the open-source `tailscaled` that nix-darwin installs. Apple's `sshd` stays off. Access rules permit `tag:korolev` to connect as `glockyco` without a prompt and permit the owner's other devices to connect as `glockyco` in check mode.
- Make `korolev` a Nix remote-build client of the Mac with `nix.buildMachines` over the `ssh-ng` protocol, with no SSH private key. Host keys come from the control plane through a packaged `KnownHostsCommand` program. `korolev` enables `systemd-resolved` and stops WSL from regenerating `resolv.conf`, so MagicDNS can be installed declaratively.
- Keep `korolev` unreachable: no inbound service, `--shields-up`, Taildrop disabled, firewall closed. The `korolevIsolation` check asserts the new declarations.
- Keep `glockyco` in the Mac's `trusted-users` with the correct rationale: a remote builder imports unsigned store paths.
- Point the Air's interactive and batch SSH endpoints and its SMB mount at the tailnet name `air`. Remove every `.local` literal and the mDNS reachability probe. Keep all Air-specific access behind one removable peer declaration.
- Document and track Air offboarding: preserve the required research results, revoke the node before returning the machine, delete its tag and policy entries, remove its SSH and SMB configuration, and remove its local credentials. No durable gate or workflow may depend on the Air.
- Add a packaged live check that builds a trivial `aarch64-darwin` derivation from `korolev` and proves that the Mac built it.
- Record the reversed isolation decision, the tailnet ownership boundary, and the node-join procedure in the architecture document and the `korolev` runbook.

## Capabilities

### New Capabilities

- `fleet-tailnet`: the tailnet that connects durable fleet hosts and declared temporary peers, the access policy that governs them, the tailnet-based SSH access to the Darwin host, and the Darwin remote builder that the Linux host uses.

### Modified Capabilities

- `personal-omp-workstation`: the WSL host network isolation requirement changes from "no shared secret, drives no other host" to "no inbound path, never a tailnet destination, holds only its tailnet device identity, drives the Darwin host as a build client".
- `repository-quality-gates`: adds the requirement that the Darwin gates can be built from the Linux host through the remote builder.

## Impact

The change affects `flake.nix` or its flake-parts modules, `modules/fleet/host.nix`, `modules/darwin/nix.nix`, a new `modules/darwin/tailscale.nix`, `modules/nixos/nix.nix`, a new `modules/nixos/tailscale.nix`, `modules/nixos/wsl.nix`, `modules/home/darwin/ssh.nix`, `modules/home/darwin/network-shares.nix`, `packages/air-batch-config-check.nix`, `packages/air-batch-check-tests.nix`, new packages for the policy renderer, the known-hosts program, and the builder check, a new `.github/workflows/tailnet-policy.yml`, `docs/architecture/personal-omp-environment.md`, and `docs/operations/wsl-omp-bootstrap.md`.

It adds `tailscale` to both host closures and changes both system derivations. Each host activates once. The temporary Air and the Windows desktop join the tailnet through Tailscale applications installed by their owners. This repository does not manage either machine. It names the desktop as a durable peer and the Air as a temporary research-results peer in policy data. Returning the Air removes its declaration and every dependent policy and client entry without changing the durable three-machine topology.

The change depends on `declare-typed-host-options`, because each host's tailnet tag is a `host.*` declaration. It has no other dependency. Later changes may use the remote builder to run Darwin gates from `korolev`.
