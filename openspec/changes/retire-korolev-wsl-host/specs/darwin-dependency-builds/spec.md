## MODIFIED Requirements

### Requirement: Ordinary fixed-output language-server toolchain

The Mac SHALL provide Markdown Oxide and Roslyn as ordinary host packages from official, fixed-output platform artifacts. Roslyn SHALL use a binary .NET runtime to launch its downloaded language-server payload. Host packages SHALL provide `markdown-oxide` and `Microsoft.CodeAnalysis.LanguageServer` without compiling either application from source, and SHALL NOT provide Marksman as an alias or fallback. No Linux workstation package set SHALL remain a consumer.

#### Scenario: Inspect the managed language-server build plan

- **WHEN** the repository checks run against a clean Darwin build of the ordinary managed language-server packages
- **THEN** the build plan contains the selected fixed-output Markdown Oxide and Roslyn artifacts
- **AND** it does not contain a Swift compiler, source-built .NET package, source-built Markdown Oxide application, or source-built Roslyn language server
- **AND** the result comes from an automated check, not from reading the plan by hand

#### Scenario: Run the upstream OMP command

- **WHEN** upstream OMP starts on the Mac with its ordinary managed language servers
- **THEN** the `markdown-oxide` and `Microsoft.CodeAnalysis.LanguageServer` executables are available on PATH
- **AND** `marksman` is absent
