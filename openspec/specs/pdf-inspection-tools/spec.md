# PDF Inspection Tools Specification

## Purpose

Provide standard command-line PDF inspection tools on the managed development workstations without project-specific installation.

## Requirements

### Requirement: PDF inspection commands

The managed Linux and macOS workstation environments SHALL provide `pdftoppm`, `pdfinfo`, and `pdftotext` on PATH after activation.

#### Scenario: Render a document page

- **WHEN** the user invokes `pdftoppm -f 1 -singlefile -png` with a valid PDF and an output prefix
- **THEN** the command produces a readable PNG of the first page

#### Scenario: Inspect document content

- **WHEN** the user runs `pdfinfo` and `pdftotext` against a valid text-bearing PDF
- **THEN** the commands report document metadata and extract its text without a project-local installation
