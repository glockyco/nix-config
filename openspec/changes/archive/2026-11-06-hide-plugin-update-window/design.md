# Design

## Context

The task runs in the logged-on user's interactive session. Its XML convergence check compares each action leaf against the desired XML.

## Goals / Non-Goals

Keep logon and hourly triggers, interactive credentials, least privilege and the runner unchanged. Do not change update retries or scheduling.

## Decisions

Run `%SystemRoot%\System32\conhost.exe` with `--headless` and a quoted PowerShell executable followed by the existing noninteractive runner invocation. Remove `-WindowStyle Hidden` because headless console creation prevents the window instead of hiding it after creation. Preserve XML escaping for both the command and complete argument string.

The existing exact action comparison detects old task XML and re-registers it. Add a regression test for that migration rather than a separate migration path.

## Risks / Trade-offs

Mocked tests establish desired XML and convergence, not visible Windows behavior. Before merging, apply on Korolev and manually run the task while watching the desktop, then confirm a fresh success entry in the log.
