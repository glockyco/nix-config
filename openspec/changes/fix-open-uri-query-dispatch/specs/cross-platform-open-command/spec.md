## MODIFIED Requirements

### Requirement: Target dispatch

With no target, `open` SHALL dispatch the current directory. With one existing Linux file or directory, it SHALL dispatch that exact target. With one absolute URI, it SHALL dispatch the URI to the Windows desktop's registered handler, including a URI with a query string or percent-escapes. Dispatch SHALL return after the Windows shell accepts or rejects the request. It SHALL NOT wait for the graphical application to exit.

#### Scenario: Open the current directory

- **WHEN** the user runs `open` without a target
- **THEN** the Windows desktop opens the current directory

#### Scenario: Open a path with spaces

- **WHEN** the user passes one existing file or directory whose path contains spaces
- **THEN** the Windows desktop opens that exact target as one argument

#### Scenario: Open an absolute URI

- **WHEN** the user passes an absolute URI with a registered Windows handler
- **THEN** the registered Windows application receives that URI

#### Scenario: Open a URI with a query string

- **WHEN** the user passes an absolute URI whose query string holds `&` and percent-escapes
- **THEN** the registered Windows application receives that URI unchanged
- **AND** no file manager window opens instead

#### Scenario: Reject an invalid target

- **WHEN** the user passes a value that is neither an existing local target nor an absolute URI
- **THEN** `open` returns a nonzero status with a clear error
- **AND** it launches no substitute target
