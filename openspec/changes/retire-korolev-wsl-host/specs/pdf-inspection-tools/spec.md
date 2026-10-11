# Spec Delta

## MODIFIED Requirements

### Requirement: PDF inspection commands

The supported macbook-pro and native Windows Korolev environments SHALL provide pdftoppm, pdfinfo and pdftotext on PATH without project-local installation. The Mac SHALL retain Nix Poppler; Windows provisioning SHALL use the native Poppler delivery owned by make-korolev-windows-native. A Linux workstation or Windows-to-WSL launcher SHALL not satisfy this contract.

#### Scenario: Render a document page

- **WHEN** the user invokes pdftoppm -f 1 -singlefile -png with a valid PDF and an output prefix on either supported machine
- **THEN** the native command produces a readable PNG of the first page

#### Scenario: Inspect document content

- **WHEN** the user runs pdfinfo and pdftotext against a valid text-bearing PDF on either supported machine
- **THEN** the native commands report document metadata and extract its text without a project-local installation
