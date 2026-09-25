## Context

See `proposal.md` for the drift. The check derives the expected version policy from roles: `SELF_UPDATING` holds the editor, relay browser, and communication client roles, and `FIXED_ROLES` pins the `browser` role to Zen with the exact policy and machine scope. Zen has an elevated WinGet resource. The renderer sets `useLatest` from the version policy.

## Goals / Non-Goals

**Goals:**

- Stop a vendor update from making Zen drift or making an apply downgrade Zen.
- Keep one version-policy rule for the whole application set.

**Non-Goals:**

- Change Zen's scope, elevation, policy file, or theme.
- Disable Zen's own updater.

## Decisions

### Add the browser role to the self-updating roles

The check keeps deriving the policy from roles, so the `browser` role joins `SELF_UPDATING_ROLES`. An alternative was a per-application exception list. It would create a second policy source beside the role rule.

### Keep the elevated installer

A self-updating machine-scope package still installs through the elevated WinGet resource. An apply upgrades Zen only when WinGet's catalog is newer than the installed version. The operator then approves the Administrator prompt, as for an initial installation.

## Risks / Trade-offs

- [The repository no longer reviews each Zen version] → Zen's vendor channel already delivers updates without review. The document now describes that fact instead of fighting it.
- [An apply can request elevation for a Zen upgrade] → The procedure tells the operator to inspect installed and catalog versions before an apply, as for the other self-updating applications.

## Migration Plan

1. Change the policy, check, and procedure. Run the gates.
1. Run `winget configure test` and confirm that `package browser` reports the desired state when the installed Zen is equal to or newer than the catalog.

Rollback: restore the exact pin at the then-current installed version.
