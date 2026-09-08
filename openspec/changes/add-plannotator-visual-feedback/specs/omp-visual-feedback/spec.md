## Purpose

Provide browser-based visual feedback on documents and assistant responses in a wrapped OMP session, without adding a planning or approval workflow.

## ADDED Requirements

### Requirement: Declarative executable and adapter ownership

The workstation SHALL supply a pinned upstream Plannotator executable on macbook-pro and korolev. The OMP adapter SHALL belong to the immutable personal plugin in `omp-agent-setup`. The adapter SHALL invoke the supplied executable without installing software, selecting versions, or loading the Plannotator Pi extension. Preferences, review history, and temporary data SHALL remain outside the Nix store and tracked source files.

#### Scenario: Launch from a clean managed session

- **WHEN** the user starts the default wrapped OMP command after the reviewed configuration is activated
- **THEN** visual annotation commands and the pinned Plannotator executable are available without a mutable plugin checkout or installer
- **AND** activation has not opened a browser or rewritten OMP configuration

### Requirement: Annotate a document snapshot

`/plannotator-annotate <document>` SHALL open a read-only snapshot of a UTF-8 text or Markdown document in Plannotator. Relative paths SHALL resolve against the invoking session's working directory. Session-local `local://` document paths SHALL resolve against that session's native mapping. Source files SHALL remain unchanged. Other resource schemes SHALL receive an explicit unsupported-target error rather than guessed filesystem resolution.

#### Scenario: Review a document with spaces in its path

- **WHEN** the user supplies a valid document path containing spaces
- **THEN** the browser displays the requested document snapshot
- **AND** submitted feedback identifies the original target
- **AND** shell interpretation cannot change the selected target

#### Scenario: Review a session-local document

- **WHEN** two sessions have different files at the same `local://` path and one requests annotation
- **THEN** the browser displays only the invoking session's document
- **AND** no directory timestamp or other session's state is used to select it

#### Scenario: Reject an unavailable target

- **WHEN** the target is missing, unreadable, not a supported document, or uses an unsupported resource scheme
- **THEN** the command reports the reason without launching a review or substituting another document

### Requirement: Annotate the last assistant response

`/plannotator-last` SHALL snapshot the most recent completed assistant response with visible text on the current conversation branch. It SHALL exclude thinking, tool calls, tool results, hidden messages, and other sessions. If no eligible response exists, it SHALL report that condition without opening the browser.

#### Scenario: Annotate after a tool-assisted answer

- **WHEN** the current branch contains an assistant answer preceded by tool results and private thinking
- **THEN** the browser displays the answer's visible text only
- **AND** feedback identifies the reviewed response rather than any later response

#### Scenario: No eligible response exists

- **WHEN** the user requests last-response annotation before a completed visible assistant response exists
- **THEN** the command reports that no response is available and starts no child process

### Requirement: Feedback returns to its originating conversation

Submitted non-empty annotations SHALL enter the originating OMP conversation once, with their source identity, reviewed snapshot identity, and annotation content preserved. If OMP is working, feedback SHALL wait as a follow-up rather than interrupt its current tool batch. The adapter SHALL NOT deliver feedback to a different session or branch after navigation. A source change during review SHALL be identified so feedback is not presented as a review of newer content.

#### Scenario: Submit highlighted corrections

- **WHEN** the user submits comments and replacement suggestions from the browser
- **THEN** OMP receives their content once as user feedback associated with the reviewed document or response
- **AND** the adapter does not apply the suggestions to files itself

#### Scenario: The source changes during review

- **WHEN** a document changes after the browser snapshot was created
- **THEN** returned feedback identifies the reviewed snapshot and warns that the source has changed

#### Scenario: Switch conversation during review

- **WHEN** the user switches sessions or changes the active conversation branch before submitting feedback
- **THEN** the pending review is cancelled
- **AND** later browser submissions cannot enter the newly selected conversation

### Requirement: Annotation-only interaction

The integration SHALL expose visual feedback without plan mode, approval controls, execution handoffs, code review, PR commands, or automatic sharing. It SHALL NOT change OMP models, thinking levels, active tools, planning state, or OpenSpec authorization rules. Submitted feedback SHALL remain feedback, not an approval signal.

#### Scenario: Comment on an implementation plan as a document

- **WHEN** the user annotates a document that happens to contain a plan
- **THEN** the interaction offers annotation rather than an approval gate
- **AND** submission does not authorize implementation or change the active planning workflow

### Requirement: Bounded review lifecycle

The integration SHALL allow one active review per OMP session and independent reviews in separate sessions. It SHALL provide `/plannotator-cancel`. Dismissal, browser tab closure, explicit cancellation, and session shutdown SHALL terminate the review without feedback or approval. Browser closure SHALL settle within a documented finite disconnect grace period. Terminal outcomes SHALL release the owned child process, listener, and temporary snapshot without deleting Plannotator user history or preferences.

#### Scenario: Close the annotation tab

- **WHEN** the user closes the review tab without submitting annotations
- **THEN** the review reports cancellation after the disconnect grace period
- **AND** no approval or implementation message reaches OMP
- **AND** the process and temporary review files are released

#### Scenario: Cancel a browser that did not open

- **WHEN** the process started but the browser did not become usable
- **THEN** the session displays review status and supports explicit cancellation
- **AND** cancellation stops the owned process without affecting another session's review

#### Scenario: Request a second review in one session

- **WHEN** the same session already has an active review
- **THEN** a second request reports that review and the cancellation command without replacing it

#### Scenario: Reject a failed review process

- **WHEN** the executable is absent, startup fails, or the result is malformed or unexpected
- **THEN** the adapter reports an error, releases owned resources, and injects no feedback or approval

### Requirement: Local browser and network boundary

Review servers SHALL listen on loopback only and SHALL open the local browser on macOS or the Windows browser for local WSL use. The integration SHALL NOT enable tailnet publication, remote sharing, firewall access, or an activation-time service. Noninteractive and remote-session invocation SHALL fail clearly rather than publish a server automatically.

#### Scenario: Annotate from WSL through Herdr

- **WHEN** a local wrapped OMP session in Herdr starts annotation on korolev
- **THEN** the Windows browser can reach the temporary review through local WSL connectivity
- **AND** the review is not reachable from another tailnet host

#### Scenario: Annotate on macOS

- **WHEN** a local wrapped OMP session starts annotation on macbook-pro
- **THEN** the local browser displays the review and feedback returns to that session
- **AND** no persistent network service is installed
