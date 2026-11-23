# Spec Delta

## ADDED Requirements

### Requirement: Persistent current-user research environment

The Windows engine SHALL converge the declared Unpaywall contact in the current user's persistent environment without elevation. Dry run SHALL detect missing, mistyped or differing values without writes. Apply SHALL change only drift, notify environment listeners after changes and verify persistence. Matching values SHALL cause no write or notification. Other environment values, including Path, SHALL be preserved.

#### Scenario: Preview an absent or incorrect contact

- WHEN the persistent contact is absent, has the wrong registry type or differs from the declaration
- THEN dry run names the resource as drift and exits nonzero without changing the registry or notifying listeners

#### Scenario: Apply the contact

- WHEN the standard account applies a drifting contact declaration
- THEN the current-user environment contains the declared contact as a literal string
- AND the engine notifies environment listeners and verifies the stored value
- AND no machine environment or unrelated user value changes

#### Scenario: Adopt the existing manual setting

- WHEN the current-user contact already matches the declaration and its registry type
- THEN dry run reports desired state and repeated apply performs no write or notification for that resource

#### Scenario: Persistence fails

- WHEN the engine cannot write or verify the declared current-user value
- THEN apply fails visibly with the existing error exit status
- AND it does not report successful convergence

## MODIFIED Requirements

### Requirement: Check expectations derive from the declaration

Checks SHALL derive mutable application/version/release/settings facts from JSON and the managed exclusion audit, not duplicate them in checker code. Shared user-environment values SHALL instead resolve from the shared TOML source named by the JSON declaration. Only stable privilege, role identity and ownership invariants SHALL be literals. Engine data SHALL remain authoritative without a second rendered declaration.

#### Scenario: Change one pin

- WHEN a reviewed version/hash changes in data
- THEN checks consume the new declaration without a matching checker edit

#### Scenario: Declare a self-updating application

- WHEN Zed, Brave or Ferdium declares present policy
- THEN checks accept an existing installation without catalog queries or application-specific version exceptions

#### Scenario: Declared application absent from the document

- WHEN a required role has no unique application in JSON
- THEN invariants fail and name the role

#### Scenario: Rendered version policy differs from the declaration

- WHEN a pinned declaration lacks its version/consumer or a present declaration carries a consumer pin
- THEN schema validation fails

#### Scenario: Review file set differs from the declaration

- WHEN a declared installation payload or prerequisite source file is missing
- THEN validation names the missing source rather than silently skip it

#### Scenario: Reject a different named application

- WHEN required Zen, Zed, Brave or Ferdium role identity changes outside the contract
- THEN invariants reject that role without copying its mutable version or profile state

#### Scenario: Resolve shared environment data

- WHEN dry run or apply reads a declared shared environment value
- THEN it uses the shared TOML from the same reviewed checkout as the engine, regardless of the active chezmoi checkout
- AND a missing, malformed, empty or unsupported reference fails validation before any mutation

#### Scenario: Detect a source change after rendering

- WHEN the shared contact source changes after the chezmoi engine hook was rendered
- THEN the hook rejects the stale inputs before starting the engine
- AND rendering the changed shared source makes the onchange hook eligible to run again
