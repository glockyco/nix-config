## ADDED Requirements

### Requirement: Monospace font for Linux rendering

The WSL host SHALL declare JetBrains Mono as a system font, so that Linux programs that render text themselves, such as headless browsers, resolve both the family `JetBrains Mono` and the generic family `monospace` to it. The font SHALL come from the pinned nixpkgs. Activation SHALL NOT change Windows fonts, Windows Terminal, or OMP's browser runtime state.

#### Scenario: Inspect the font configuration before activation

- **WHEN** the WSL host configuration is evaluated
- **THEN** its system font packages contain the pinned JetBrains Mono package

#### Scenario: Resolve the monospace families on the running host

- **WHEN** the operator queries fontconfig on the activated host
- **THEN** `fc-match "JetBrains Mono"` and `fc-match monospace` both resolve to JetBrains Mono

#### Scenario: Render a terminal recording

- **WHEN** VHS renders a tape with `Set FontFamily "JetBrains Mono"` on the activated host
- **THEN** the recorded terminal text uses JetBrains Mono rather than a proportional fallback
