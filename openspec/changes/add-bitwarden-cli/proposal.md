# Proposal

## Why

Coding agents need the official Bitwarden CLI on both workstations. Workstation configuration should install that prerequisite without owning the vault lifecycle implemented by the personal OMP plugin.

## What Changes

- Install native `bw` through the existing Mac and Windows package owners.
- Require binary-cache availability for the locked Mac package and its dependencies.
- Register and test the Windows CLI role with standard-user installation and present policy.
- Point the Secrets documentation to the personal OMP plugin for vault use.

## Capabilities

### New Capabilities

- `bitwarden-secrets`: Native Bitwarden CLI availability as a host prerequisite, with vault use delegated to the personal OMP plugin.

### Modified Capabilities

None. Existing workstation ownership and dependency-build contracts remain unchanged.

## Impact

- Mac user CLI package declaration.
- Windows application declaration, role validation and tests.
- README Secrets documentation.
- No vault directories, server configuration, authentication, unlock cache, approvals, secret delivery or model-bound scrubbing in this repository. The personal OMP plugin owns those behaviors.
- Existing age credentials and desktop/browser installations remain unchanged.
