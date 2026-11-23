# Proposal

## Why

Tern delivers OMP on both workstations, but Mac shells and the personal-plugin job still select an older standalone installation. Align executable selection and operating guidance with Tern so SSH sessions and scheduled updates use the same runtime as interactive sessions.

## What Changes

- Prefer Tern's managed OMP directory in Mac zsh startup without removing the local tools directory or Tern CLI.
- Run both personal-plugin update commands through Tern's Mac executable.
- Replace Mac installer and self-update guidance with Tern ownership. Do not document unsupported release recovery.
- Test shell precedence and scheduled command selection without changing the live Mac configuration or deleting its older executable.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `personal-omp-workstation`: Tern owns OMP delivery and updates on both hosts, including Mac shell resolution and recovery boundaries.
- `personal-plugin-updates`: The Mac job invokes Tern's executable independently of shell startup.
- `omp-update-guidance`: Current guidance uses Tern rather than installer or self-update commands.

## Impact

Changes affect Mac chezmoi shell templates, the Darwin launch agent, their checks, and repository guidance. Windows executable ownership and application runtime state stay unchanged. The stale Mac executable remains until configuration is merged and applied, after which removal is a separate authorized operation.
