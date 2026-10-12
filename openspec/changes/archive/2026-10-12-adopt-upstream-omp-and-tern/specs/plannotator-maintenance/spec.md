## MODIFIED Requirements

### Requirement: Shared unmodified vendor package

Both workstation hosts SHALL select Plannotator from the same commit-pinned vendor input as an ordinary host package. Each host SHALL use its unmodified vendor package, including vendor packaging patches and dependencies. The workstation SHALL NOT append a downstream client-lease patch or maintain a separate package recipe. Delivery SHALL not depend on an OMP wrapper.

#### Scenario: Evaluate the final host compositions

- **WHEN** each host resolves its ordinary annotation executable after the upstream OMP cutover
- **THEN** its selection equals the corresponding unmodified `plannotator-packages` vendor package
- **AND** both hosts use the declared vendor revision and application version
- **AND** other tool selections retain their declared owners

### Requirement: Preserve existing verification and runtime contracts

The on-demand pin SHALL preserve required native checks and the annotation-only adapter contract through the plugin-manager installation. Plannotator delivery SHALL NOT add custom CI caching, installers, approval controls, automatic activation, mutable source checkouts, or network publication. Documentation SHALL distinguish source pinning from guaranteed build reuse. Closing a browser tab MAY leave a review pending until explicit cancellation, session navigation, or shutdown.

#### Scenario: Verify the final stock selection

- **WHEN** the maintenance change is submitted for acceptance
- **THEN** evidence verifies the complete Nix dependency updater command and both ordinary host selections against the final unmodified vendor package
- **AND** ordered native checks and the Darwin build-plan and system-build gates pass for that selection
- **AND** real upstream sessions in Tern verify annotation-only feedback, cancellation, browser/network boundaries, activation, and applicable package rollback

#### Scenario: Recover a pending review

- **WHEN** a browser tab closes while its review remains pending
- **THEN** `/plannotator-cancel` remains available to stop the owned review
- **AND** the integration does not promise automatic tab-close settlement or substitute approval mode, a new timeout, or a fallback
