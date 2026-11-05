# Proposal

## Why

Existing Keynote decks need Apple's application for reading and exporting. The application inventory supports Homebrew casks and existing bundles, but cannot declare Mac App Store installation.

## What Changes

- Extend typed application records with a positive App Store ID and a display name for the generated Brewfile.
- Derive nix-darwin's Mac App Store applications and its `mas` prerequisite from the same inventory as casks, Dock entries and login starts.
- Declare Keynote in the Mac's shared application inventory.
- Extend inventory validation and host configuration checks, and describe App Store activation prerequisites beside the inventory guidance.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `repository-quality-gates`: Application records can own App Store installation without a second application list, while retaining typed validation and host-derived checks.

## Impact

The shared host TOML, typed host option, Darwin desktop Homebrew role, inventory checks and README application guidance change. Activation uses nix-darwin's existing Homebrew integration and requires an interactive App Store sign-in. No activation or account operation is part of implementation verification.
