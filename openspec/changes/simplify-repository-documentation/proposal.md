## Why

Current documentation repeats configuration, operating instructions, and planning state across thousands of lines, making the repository difficult to read and maintain. Existing cleanup proposals reorganize that material rather than remove its ongoing maintenance cost.

## What Changes

- Make one concise README the human entry point for purpose, hosts, development, activation, bootstrap, and recovery.
- Remove the architecture manual, duplicate configuration descriptions, and delivered-work summaries after preserving unique necessary information. Keep the distinct legacy plans and their index; planning migration is outside this cleanup.
- Retain a separate operating procedure only when essential bootstrap or recovery instructions cannot fit clearly in the README. Each exception must explain a concrete reader need, not preserve an existing file by default.
- Reduce agent guidance to repository-specific instructions and links. Use declarations, executable checks, and nearby rationale instead of parallel prose inventories.
- Review all current documentation, including accepted specs and active planning artifacts, for obsolete references and duplicated implementation descriptions. Preserve accepted behavioral requirements and unrelated pending work.
- Supersede the documentation approaches in `align-documentation-with-fleet` and `consolidate-planning-home` during implementation. Preserve their unique unresolved intent without executing their proposed documentation framework or creating speculative workstreams.
- Keep OpenSpec as the existing planning workflow. Do not generate documentation, add documentation-policy checks, or migrate content wholesale into another documentation tree.

## Capabilities

### New Capabilities

None. This is a documentation-only change; `.openspec.yaml` declares `skip_specs: true`.

### Modified Capabilities

None. Existing behavioral contracts and runtime behavior remain unchanged. Spec edits are limited to equivalent wording and current references.

## Impact

Scope: `README.md`, `AGENTS.md`, `docs/`, documentation references in source and workflows, and affected OpenSpec text. Archived changes remain historical records, not required reading for ordinary operation.

No host activation, executable update, dependency change, new runtime command, external issue creation, or external-service mutation is authorized. The two earlier cleanup proposals remain untouched while this proposal is being prepared. Implementation requires separate authorization.
