## Why

Korolev's `open` hands an absolute URI to `explorer.exe`. Explorer dispatches a URI without a query string to its registered handler, but opens the Documents folder for any URI that contains `?`. OAuth sign-in URLs, search links and most web application links carry a query string, so they never reach the browser. The specified URI scenario fails for them.

## What Changes

- Dispatch an absolute URI through the Windows shell's URL protocol handler, `rundll32.exe url.dll,FileProtocolHandler`, instead of `explorer.exe`. Existing Linux paths keep their translation and `explorer.exe` dispatch.
- Report a missing `rundll32.exe` as an unavailable interoperation boundary, without a fallback opener.
- Extend the behavior check with the URI route and its missing-executable case.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `cross-platform-open-command`: An absolute URI with a query string reaches its registered Windows handler.

## Impact

`packages/wsl-open/` and its behavior check. Korolev activation installs the updated command. Paths, argument count rules, errors and the activation boundary are unchanged.
