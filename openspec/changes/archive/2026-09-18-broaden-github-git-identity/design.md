## Context

Korolev declares the SCCH address as its global Git identity. Home Manager adds a conditional include for `~/src/github.com/glockyco/`, so GitHub repositories under other owners inherit the SCCH address. Git configuration scope gives repository-local settings higher precedence than global settings and global conditional includes.

The shared Git module intentionally excludes identity because identities differ by host. The Korolev host declaration therefore owns this policy.

## Goals / Non-Goals

**Goals:**

- Select the GitHub no-reply address from the checkout host path, independent of repository owner.
- Preserve the SCCH address as the global default.
- Preserve standard repository-local override precedence.
- Keep activation declarative and free of repository-local writes.

**Non-Goals:**

- Change Git identity on the Mac.
- Select identity from a repository remote URL.
- Change GitHub authentication, transport, or credentials.
- Add repository-local configuration during activation.

## Decisions

### Match the complete GitHub checkout tree

Change the existing `includeIf` condition to `gitdir:~/src/github.com/`. Git applies the no-reply address to every worktree below that path. Repository ownership does not affect selection.

Keeping the SCCH address as the global value makes repositories below `~/src/gitlab.scch.at/` and other locations use the work identity without another conditional include. An explicit SCCH include was rejected because it would duplicate the global default without changing precedence.

### Keep the policy in the Korolev host declaration

The host declaration continues to own both identities and the conditional include. Moving either identity into the shared Git module was rejected because the Mac has a different default and needs no work-address fallback.

### Verify generated and activated behavior

Verification uses the generated Home Manager Git configuration in an isolated temporary home before activation. After activation, disposable repositories below both live host trees verify path selection and a repository-local override. This checks Git's effective precedence rather than only the Nix attribute values.

## Risks / Trade-offs

- A repository below `~/src/github.com/` uses the no-reply address even if its remote is not GitHub. This is intentional because the checkout layout defines identity ownership. A repository-local override handles exceptions.
- A GitHub repository cloned outside `~/src/github.com/` keeps the SCCH default. The bootstrap guidance identifies the managed checkout root.

## Migration Plan

1. Broaden the conditional include and update the bootstrap guidance.
1. Evaluate the generated configuration and run the repository gates.
1. Commit the reviewed configuration before activation.
1. Activate Korolev and inspect activation output.
1. Verify both live checkout trees and repository-local precedence with disposable repositories.

A NixOS generation rollback restores the previous conditional include if activation exposes an unexpected conflict.
