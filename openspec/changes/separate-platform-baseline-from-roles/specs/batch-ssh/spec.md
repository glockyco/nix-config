## MODIFIED Requirements

### Requirement: Explicit remote tool resolution

While the temporary Air client role is enabled, automation that invokes a tool absent from the Air's non-interactive `PATH` SHALL receive the reviewed absolute executable path from the Air endpoint declaration. The role SHALL pass that path to the packaged command and its check. The batch endpoint SHALL NOT modify remote shell initialization to discover such tools. Removing the role and declaration SHALL remove this endpoint completely.

#### Scenario: Remote Docker command

- **WHEN** automation invokes Docker through the batch endpoint
- **THEN** it uses the remote Docker executable from the endpoint declaration
- **AND** it does not depend on shell startup files or an ambient environment variable to resolve `docker`

#### Scenario: Change the remote Docker path

- **WHEN** the endpoint declaration changes its remote Docker executable
- **THEN** the installed batch command and its repository check use the new path
- **AND** neither consumer needs a matching literal edit
