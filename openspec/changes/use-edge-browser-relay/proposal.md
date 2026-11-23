# Proposal

## Why

Korolev's OMP browser relay runs in Microsoft Edge, where the signed-in SCCH services such as Personalwolke live. The declared Brave relay browser is installed but unused there. Since OMP 19.1 the relay runs through the extension's native messaging host, and `omp browser-relay install` registers that host only for Chrome, so Edge needs its own registration after every reinstall.

## What Changes

- The Windows relay browser is Microsoft Edge, which Windows provides and keeps current. The engine declares no package for it.
- Brave leaves the Windows application set and its role contract. The Mac keeps Brave.
- The Korolev guide says how to set up the relay in Edge: run `omp browser-relay install`, register its native host for Edge, and load the extension once.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `windows-workstation-layer`: the relay browser is the system-provided Edge instead of a declared Brave package.

## Impact

`windows/workstation.json`, `windows/Workstation.Validation.ps1`, `docs/operations/korolev-windows.md` and the Windows workstation spec. Applying the change leaves an installed Brave in place, and the operator removes it with WinGet if wanted.
