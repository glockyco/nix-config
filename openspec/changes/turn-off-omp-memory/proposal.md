# Proposal

## Why

OMP's memory gives every session the bank of the folder it started in, with the instruction to follow it. A model writes the bank from earlier chats, so it holds inferences as rules, and a bank for a shared folder such as `/tmp` mixes projects. On 2026-11-01 the `/tmp` bank on the Mac held Orivaeon's visual language beside compendium decisions, and it had turned a screenshot into the standing rule "Use Sunken Temple; do not switch to an alternative." Each project's repository and the notes vault already hold its decisions, which a person approves.

## What Changes

- The README's OMP block and the Korolev runbook set `memory.backend` to `off`, and the README gives the reason.
- The workstation spec stops porting memory banks between hosts and requires memory off.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `personal-omp-workstation`: the mutable state boundary no longer ports sharpshooter banks, and a new requirement keeps memory off.

## Impact

Sessions on both hosts start without memory. The banks stay on disk, and nothing reads them while memory is off.
