## ADDED Requirements

### Requirement: Verified Plannotator advancement

Explicit platform source/release selection SHALL preserve required native gates. Maintenance SHALL introduce no custom CI caching, automatic activation, mutable source checkout or Linux fallback. Windows SHALL retain its existing explicit official installer rather than gain another installer. Documentation SHALL distinguish pins from guaranteed build reuse.

#### Scenario: Verify the final stock selection

- **WHEN** maintenance is submitted for acceptance
- **THEN** evidence verifies the updater behavior and both native vendor selections
- **AND** ordered native checks and Mac build-plan/system-build gates pass where applicable
- **AND** a Plannotator update is checked in a fresh OMP session with `/plannotator-annotate` and `/plannotator-last`

## REMOVED Requirements

### Requirement: Preserve existing verification and runtime contracts

**Reason**: It bound maintenance to the personal plugin's annotation adapter and its cancellation command, which no longer exist.
**Migration**: "Verified Plannotator advancement" keeps the native gates and checks updates with the official plugin's commands.
