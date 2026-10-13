## Purpose

Provide browser-based visual feedback on documents and assistant responses in a local upstream OMP session, without adding a planning or approval workflow.

## Requirements

### Requirement: Declarative executable and adapter ownership

The Mac SHALL retain ordinary unmodified Plannotator from its commit-pinned vendor Nix input; native Korolev SHALL use C3's official native release installation. The adapter SHALL belong to the published personal plugin installed by OMP's user manager, including released support-native-windows. It SHALL invoke the supplied executable without installing/selecting versions or loading the Pi extension. Preferences, history and temporary data SHALL remain outside store/tracked files.

#### Scenario: Launch from a clean managed session

- **WHEN** the user starts the platform-owned upstream OMP in Tern after reviewed packages and the personal plugin are installed
- **THEN** annotation commands and the selected native Plannotator resolve from the plugin manager and host PATH
- **AND** activation has not installed the plugin, opened a browser or rewritten OMP configuration

### Requirement: Unmodified vendor package delivery

Each host SHALL use unmodified vendor Plannotator through its declared platform owner, without a local lease patch or separate package recipe. Application advancement SHALL require an explicit reviewed platform source/release change and annotation/cancellation verification. Delivery SHALL not require an upstream contribution, custom CI caching or a cross-host Nix package. Version provenance SHALL be recorded independently for both native installations.

#### Scenario: Select the vendor package

- **WHEN** both hosts resolve their annotation executable
- **THEN** the Mac selects its unmodified pinned vendor package and Windows its accepted official release
- **AND** browser, network, lifecycle, activation and recovery acceptance remain required

#### Scenario: Update the selected package

- **WHEN** an explicit Plannotator update changes the Mac source revision or Windows release selection
- **THEN** review verifies annotation-only feedback and explicit cancellation on affected hosts
- **AND** routine complete flake lock updates cannot advance the declared Mac application source

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

### Requirement: Explicit review lifecycle

The integration SHALL allow one active review per OMP session and independent reviews in separate sessions. It SHALL provide `/plannotator-cancel`. Dismissal, explicit cancellation, session navigation, and session shutdown SHALL terminate the review without feedback or approval. Browser tab closure MAY leave a review pending and SHALL NOT imply approval. The integration SHALL NOT promise automatic tab-close settlement or add approval mode, a timeout, or a fallback to obtain it. Terminal outcomes SHALL release the owned child process, listener, and temporary snapshot without deleting Plannotator user history or preferences.

#### Scenario: Recover after closing the annotation tab

- **WHEN** the user closes the review tab without submitting annotations and the review remains pending
- **THEN** the session retains pending status and supports `/plannotator-cancel`
- **AND** explicit cancellation releases the owned process, listener, and temporary review files
- **AND** no feedback, approval, or implementation message reaches OMP

#### Scenario: End the owning session

- **WHEN** the session shuts down or navigates to another session or branch during a pending review
- **THEN** the adapter cancels the owned review and releases its resources
- **AND** later browser submissions cannot enter another conversation

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

### Requirement: Host-local annotation browser boundary

Review servers SHALL bind loopback only and open the host-local browser on Mac and native Windows Korolev. No Linux relay, tailnet publication, remote sharing, firewall access or activation service SHALL be used. Noninteractive/remote invocation SHALL fail clearly rather than publish automatically. Native Windows acceptance SHALL depend on the released support-native-windows adapter.

#### Scenario: Annotate natively through Tern on Windows

- **WHEN** a local native OMP session in Tern starts annotation in a Korolev Windows checkout
- **THEN** the Windows browser reaches the temporary native loopback review and feedback returns to that session
- **AND** no NixOS distribution, Linux listener or tailnet publication participates

#### Scenario: Annotate on macOS

- **WHEN** a local upstream OMP session in Tern starts annotation on macbook-pro
- **THEN** the local browser displays the review and feedback returns to that session
- **AND** no persistent network service is installed
