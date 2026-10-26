# Spec Delta

## MODIFIED Requirements

### Requirement: Declared native fleet access policy

Repository-rendered policy SHALL grant every tailnet node access to declared reachable members, including native Windows Korolev, the Mac, desktop, the second personal desktop desktop-ac and temporary Air. It SHALL generate positive port-22 tests and synthetic unreachable-destination rejection tests. It SHALL contain no email addresses or Tailscale SSH authorization. Reviewed separate test/deploy identities and protected-main acceptance SHALL remain effective; no retired host gate SHALL authorize deployment.

#### Scenario: Render the policy

- **WHEN** the repository renders the policy
- **THEN** the output is a valid policy document with one grant set, tag owners for every declared tag, and network tests
- **AND** it contains no Tailscale SSH rules or SSH tests

#### Scenario: Reach the second personal desktop

- **WHEN** desktop-ac is enrolled with tag:desktop-ac and another fleet machine connects to it by its tailnet name
- **THEN** the policy permits the network path
- **AND** membership alone does not authorize any Windows account access

#### Scenario: A rule names an unreachable host as a destination

- **WHEN** policy data lists any reachable = false host tag as a destination in a grant
- **THEN** evaluation fails

#### Scenario: A rule names an unreachable fixture as a destination

- **WHEN** a synthetic policy fixture marks a host unreachable and names that tag as a grant destination
- **THEN** policy evaluation rejects the destination
- **AND** no real Korolev/Linux host is required to prove this invariant

#### Scenario: A rule carries an e-mail address

- **WHEN** declared policy data contains an @ character
- **THEN** evaluation fails

#### Scenario: Apply a reviewed policy

- **WHEN** a pull request changes the policy data
- **THEN** CI renders policy and runs live policy tests with read-only provider authorization
- **AND** successful required checks on the exact main revision permit deployment through a separate write identity
- **AND** that identity rejects PR-issued tokens and constrains the repository, main ref and deployment workflow

#### Scenario: Main protection

- **WHEN** a change is proposed for main
- **THEN** GitHub requires a pull request, current Darwin, Linux-generic, Windows and portable OpenSpec checks, and the live policy test
- **AND** administrators cannot bypass protection, create nonlinear history, force-push or delete main

#### Scenario: Overlapping policy deployments

- **WHEN** multiple successful main checks request policy deployment
- **THEN** apply jobs do not overlap or automatically cancel an in-progress apply
- **AND** a checked revision no longer current main is not applied
- **AND** failure to query current main fails rather than allowing the write

#### Scenario: Failed native checks

- **WHEN** a required check fails, including portable OpenSpec, or the completed workflow was a PR check
- **THEN** no policy apply is authorized by that completion event

#### Scenario: Connect to native Korolev

- **WHEN** the Mac or desktop connects to Windows Korolev over the tailnet
- **THEN** policy permits the network path and its independently approved OpenSSH key authenticates
- **AND** membership alone does not authorize Windows account access

#### Scenario: Retire the Linux host

- **WHEN** the NixOS distribution and its host declaration are retired
- **THEN** no Linux host identity, service or policy dependency remains
- **AND** native Windows Korolev remains reachable only through its approved native service/account boundaries

#### Scenario: No real unreachable destination remains

- **WHEN** every declared fleet node is reachable
- **THEN** generated tests positively exercise reachable SSH paths instead of carrying empty deny-only tests
- **AND** synthetic unreachable-host fixtures still prove deny generation and forbidden destination rejection
