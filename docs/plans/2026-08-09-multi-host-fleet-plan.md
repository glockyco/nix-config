# Multi-Host Fleet Architecture

Status: draft. The repository shape and host boundaries are decided; the
remaining network, account, and deployment details are recorded below.

## Goal

Run one declarative configuration as a small fleet: the Apple Silicon MacBook
Pro remains the daily driver and orchestrator, while narrowly scoped Linux
workers can run batch jobs on the two Windows desktops. Keep each person's
identity and decryption authority independent, and make a worker removable
without changing its owner's Windows machine.

The university MacBook Air is excluded. It is temporary equipment due back next
month, not future infrastructure; the family backup plan explicitly gives it a
return-and-evacuation path rather than a place in the fleet.

## Principles

- One repository and one lock file are preferable to duplicated shared modules
  or cross-repository input coordination.
- A host owns its hostname, username, architecture, and other identity. Shared
  modules must not assume that every host has the same person behind it.
- Shared infrastructure does not mean shared credentials or decryption
  authority. Independent identities and explicit shared spaces are required.
- Privacy from the operator is a boundary: an operator who can administer a
  machine must not automatically be able to decrypt another person's private
  data.
- WSL2 is a side-car Linux environment. Windows keeps gaming, GPU access, and
  anti-cheat workloads; the worker does not require dual boot or repartitioning.
- Agents receive only the data and capabilities they need. Declarative text is
  easy for an LLM agent to review and edit; encrypted private values remain
  opaque unless the agent is deliberately given the corresponding authority.

## Fleet roster

| Host                          | System           | Role and status                           | Boundary                                                                |
| ----------------------------- | ---------------- | ----------------------------------------- | ----------------------------------------------------------------------- |
| `macbook-pro`                 | `aarch64-darwin` | Active daily driver and orchestrator      | User-owned macOS host; controls fleet changes and CI policy             |
| User's Windows desktop (WSL2) | `x86_64-linux`   | Planned NixOS-WSL host                    | User-owned Windows machine; Linux is a side-car for Nix work            |
| Wife's Windows machine (WSL2) | `x86_64-linux`   | Planned, deliberately scoped batch worker | Separate Linux user, non-administrative Windows account, narrow secrets |
| University MacBook Air        | Not applicable   | **Excluded** temporary equipment          | Return next month; not future infrastructure                            |

The MacBook Air must not be made a fleet host while it is available. Its `air`
and `air-batch` entries in `modules/home/ssh.nix`, the `air-batch-check` package
and flake outputs, and their README guidance are scheduled for removal together
as part of return preparation. This is consistent with the family backup plan's
rule that only personally owned data is evacuated from the university device.
The return change must remove this complete access surface in one step:

- Delete the `airHost`, `air`, `air-batch`, and `airBatchCheck` declarations from
  `modules/home/ssh.nix`.
- Delete `packages/air-batch-check.nix`,
  `packages/air-batch-check-tests.nix`, and
  `packages/air-batch-config-check.nix`.
- Delete the `airBatchCheck`, `airBatchCommandTest`, and `airBatchConfigCheck`
  bindings from `flake.nix`, including
  `packages.aarch64-darwin.air-batch-check`,
  `checks.aarch64-darwin.airBatchCommand`, and
  `checks.aarch64-darwin.airBatchConfiguration`.
- Delete the MacBook Air SSH section and the SMB bootstrap step from
  `README.md`.
- Delete `modules/home/network-shares.nix` and its import from
  `modules/home/default.nix` so the `~/Air` link and mount agent disappear with
  the SSH endpoints.

The archived OpenSpec change remains historical evidence. It is not active
workstation configuration.

## One repository, many hosts

Separate repositories were rejected. They would either duplicate shared modules
or introduce a flake-input indirection. In the latter case, every shared-module
edit would require a commit, push, and lock-file bump in each consuming
repository before the change could be tested. One repository keeps one
`flake.lock`; the fleet moves nixpkgs in lockstep and shared-module changes are
tested at their source.

This does not make all hosts identical. `hosts/<name>/default.nix` is the
boundary where a host supplies its identity and selects the shared modules.
The cost is a larger checkout and a coordinated fleet upgrade. The lock-in is
to one repository's release cadence and a shared nixpkgs pin, rather than to a
vendor-specific fleet manager. An LLM agent can read and write the Nix modules,
host definitions, and lock metadata directly; encrypted secret contents remain
unreadable without an explicitly granted key.

## flake-parts and per-system evaluation

Before the fleet work, the flake hardcoded `system = "aarch64-darwin"` and
derived `pkgs` from the Darwin configuration, so nixpkgs was evaluated once.
That was an elegant choice for one host. flake-parts was not worth its extra
structure for a single host; the need to support two architectures is what
changed the judgement.

The flake now declares `aarch64-darwin` and `x86_64-linux`, and `perSystem`
replaces the single-system output shape. Darwin outputs reuse the package set
from `darwinConfigurations.macbook-pro`; Linux outputs use the corresponding
nixpkgs package set with the local overlay. This allows the same repository to
expose system-specific checks, packages, and shells without pretending that
Darwin and Linux have the same package set.

The migration has a one-time complexity and evaluation cost: maintainers must
understand flake-parts' `perSystem` boundary and CI evaluates more than one
system. Its lock-in is a small dependency on flake-parts' module conventions,
while the resulting outputs remain ordinary flake outputs. Agents can inspect
and edit the per-system Nix as structured, textual data, but they must keep
system-specific conditionals explicit rather than assuming the MacBook Pro's
package set applies everywhere.

## Host identity is per host

`hostname` and `username` were global `let` bindings. They now live in
`hosts/<name>/default.nix`, where the host passes them to nix-darwin as
`specialArgs`. The current `macbook-pro` host therefore owns `hostname = "macbook-pro"` and `username = "glockyco"`; a future host can have a different
user without changing shared modules.

The cost is one small host file and a little repetition per machine. The
lock-in is low: this is a repository convention, not a deployment service. An
LLM agent can safely read and update a host's identity in one obvious file, but
must treat usernames and hostnames as sensitive operational metadata and must
not infer one host's identity for another.

## WSL2 side-car architecture

Windows has no native Nix environment: the daemon, `/nix` store, and builders
assume POSIX facilities. Nix on a Windows box therefore runs inside a Linux VM.
WSL2 is the least-friction VM for this use. It is a side-car rather than a
replacement desktop: gaming, the GPU, and anti-cheat remain on native Windows,
with no dual boot and no repartitioning.

Each planned WSL host has a one-time Windows setup:

1. Provision the WSL2/NixOS-WSL environment and its Linux user boundary.
1. Install the Windows **OpenSSH Server** optional feature.
1. Set the OpenSSH login shell so the connection enters the intended WSL-side
   workflow rather than an accidental default shell.
1. Install the key with the correct ACLs. An administrator login may cause
   OpenSSH to read `%ProgramData%/ssh/administrators_authorized_keys` under
   restricted ACLs instead of the ordinary `~/.ssh/authorized_keys`; a standard
   login uses the ordinary per-user path. Confirm which account class applies
   before debugging a missing key.

WSL2 adds Windows disk usage, memory overhead, and another update boundary. Its
lock-in is to Windows plus the WSL2/NixOS-WSL integration, although the Linux
configuration and store remain exportable files rather than a proprietary
fleet database. An LLM agent can read and write the NixOS-WSL configuration,
SSH configuration, and batch-job data available to its Linux user. It cannot
reliably manage native Windows or GPU state through the Linux configuration,
which is an intentional boundary.

## Boundary on the wife's machine

The wife's machine is more powerful than the user's Windows desktop, but it is
not the user's hardware. Its worker is therefore deliberately scoped rather
than a general-purpose remote administrator. This applies the family backup
plan's rules for independent identities and privacy from the operator:

- The worker is a separate Linux user inside WSL. It is not the Windows user's
  administrator and must not be granted Windows administrative rights.
- It has its own age key. Its SOPS recipient set is deliberately narrow and
  contains only secrets needed for the worker's batch jobs; it can never
  decrypt the user's personal secrets.
- Shared data, if any, is an explicit share. The worker must not receive a
  personal home directory, a blanket repository of private backups, or an
  implicit operator decryption capability.
- The workload is batch-style only. Interactive administration, gaming control,
  and broad host orchestration are outside this worker's role.
- Removal is one `wsl --unregister` operation for the worker distribution. That
  deletes the WSL worker state while leaving the wife's Windows installation,
  files, accounts, and other applications untouched.

The cost is setup and ongoing maintenance of a second identity, age key, and
explicit data share; batch capacity is traded for less convenience. The
lock-in is limited to WSL2 and SOPS/age formats; it is not lock-in to the
wife's Windows account, and the worker has the explicit `wsl --unregister`
removal path. An LLM agent can
read and write the worker's declarative configuration and permitted batch data,
but encrypted personal secrets are intentionally opaque and unavailable to it.
That limitation is a security property, not an automation defect.

## Verification and CI

`nix flake check` checks only the system on which it runs. CI therefore runs a
matrix containing `macos-15` and `ubuntu-latest`, so both declared system paths
are evaluated. The CI cost is additional runner time and maintenance. The
provider's runner environments are a modest operational lock-in, mitigated by
keeping the check command ordinary Nix. Agents can read the workflow and check
output and can write the Nix and workflow text, but cannot treat a green result
on one runner as proof for the other architecture.

The restructure was behaviour-preserving. The built `darwin-system` derivation
is identical to the pre-restructure derivation except for
`darwin-version.json`. That file embeds `system.configurationRevision`, so its
contents necessarily differ between commits even when the rest of the built
system is unchanged. This is evidence for equivalence, not a claim that every
future host or output has identical behaviour.

## Decision trade-offs

| Decision                         | Cost                                         | Lock-in                                    | LLM agent read/write quality                                           |
| -------------------------------- | -------------------------------------------- | ------------------------------------------ | ---------------------------------------------------------------------- |
| One repository and one lock file | Coordinated upgrades and a larger checkout   | Shared release cadence and nixpkgs pin     | Excellent for modules, hosts, and lock metadata; secrets remain opaque |
| flake-parts with `perSystem`     | More structure and multi-system evaluation   | flake-parts module conventions             | Excellent for declarative text; system branches need explicit review   |
| Per-host identity                | One identity stanza per host                 | Low; repository convention only            | Excellent; each edit has one obvious host file                         |
| WSL2 side-car                    | Windows disk, RAM, and setup overhead        | Windows plus WSL2 integration              | Good inside Linux; not a control plane for native Windows/GPU state    |
| Wife's scoped worker             | Separate user, key, and share administration | WSL2 and SOPS/age, with unregister removal | Good for allowed batch data; cannot read personal secrets by design    |
| Matrix CI                        | Extra runner minutes and maintenance         | Some dependence on runner images           | Good for checks and logs; agents must compare both systems             |

## Decisions still open

- The user's Windows desktop hostname and network address are unknown. It may
  simply have been powered off during discovery.
- Name resolution: choose among a DHCP reservation, a router DNS entry, and
  Tailscale MagicDNS.
- Whether to enable nix-darwin's `linux-builder` so the Mac can build
  `x86_64-linux` closures locally.
- Whether each Windows login is an administrator or standard account. This
  determines whether OpenSSH reads
  `administrators_authorized_keys` under restricted ACLs or the ordinary
  `~/.ssh/authorized_keys`.
- Whether a deployment tool such as deploy-rs is worth adopting later.

## References

- [Repository README](../../README.md)
- [Family Backup, Storage, and Continuity plan](2026-08-08-family-backup-storage-plan.md)
- [Current flake](../../flake.nix)
- [Current MacBook Pro host](../../hosts/macbook-pro/default.nix)

## Done when

The one-repository flake evaluates both declared systems; the active MacBook Pro
remains the orchestrator; each planned WSL host has a documented OpenSSH and
login boundary; the wife's worker has an independent Linux identity and narrow
SOPS recipients; unregistering it leaves her Windows machine untouched; CI
checks both `macos-15` and `ubuntu-latest`; the derivation comparison remains
understood; and the MacBook Air is returned and removed from `modules/home/ssh.nix`
without becoming fleet infrastructure.
