## Context

See `proposal.md` for the motivation.

`korolev` already enables `programs.nix-ld`, which supplies the conventional loader for unpatched Linux executables. Its pinned nixpkgs module exposes only libraries inherited from Nix and systemd by default. OMP's managed Chrome for Testing 150.0.7871.24 therefore stops at `libglib-2.0.so.0`; `ldd` reports missing GLib, NSS, accessibility, D-Bus, printing, audio, GBM, Pango, Cairo, X11, and keyboard libraries.

A diagnostic library path made from the pinned package set started that exact browser, loaded `https://example.com`, and rendered a valid PNG. The required additions are `glib`, `nss`, `nspr`, `at-spi2-core`, `dbus`, `cups`, `expat`, `libxcb`, `libxkbcommon`, `alsa-lib`, `libgbm`, `libX11`, `libXext`, `cairo`, `pango`, `libXcomposite`, `libXdamage`, `libXfixes`, and `libXrandr`. The default set already provides `libudev` through systemd.

The relay daemon also starts successfully on `127.0.0.1:9224`, but it waits for an extension connection. Zen cannot load the Chrome MV3 extension. Google Chrome is recorded as centrally managed but is not currently installed. Microsoft Edge exists, but its ownership and future policy belong to the employer. The Mac already uses Brave only for the OMP relay.

## Goals / Non-Goals

**Goals:**

- Make OMP's managed headless Chromium run through the existing NixOS foreign-binary loader.
- Provide a dedicated Windows browser and profile for authenticated relay sessions.
- Keep browser startup, extension loading, authentication, and mutable state explicit.
- Preserve system-generation and Windows-configuration rollback boundaries.

**Non-Goals:**

- Package or pin OMP's Chromium download through Nix.
- Replace Zen or change the Windows default browser.
- Use employer-managed Edge or Chrome for personal authenticated automation.
- Start a browser, relay daemon, or extension during activation.
- Give OMP control of ordinary browsing tabs or profiles.

## Decisions

### 1. Extend `nix-ld` at system scope

`modules/nixos/programs.nix` adds the tested libraries to `programs.nix-ld.libraries`. NixOS merges them with the module's default list and publishes one generation-owned `/run/current-system/sw/share/nix-ld/lib` path.

This uses the supported NixOS interface already selected for prebuilt project executables. It does not add `LD_LIBRARY_PATH` to the OMP wrapper, because that would couple a portable wrapper to one host's desktop ABI and leak the path into every OMP child process. It does not replace OMP's browser with `pkgs.chromium`, because Puppeteer selects and owns a compatible browser release.

### 2. Check shared-library names, then smoke the real browser

A repository check inspects the WSL system path and requires the browser's shared-library names under `share/nix-ld/lib`. It checks the compatibility surface rather than duplicating the package list. It also rejects a Nix-packaged Chromium in the workstation wrapper closure.

The acceptance smoke runs the actual OMP-managed browser after activation. It opens a public HTTPS page and captures a screenshot. This live smoke remains necessary because OMP can update its browser independently of the Nix generation. An OMP update repeats the smoke before acceptance.

Alternative rejected: fetch a second Chrome archive in a Nix check. That would duplicate OMP-owned runtime state and create an unrelated browser update obligation.

### 3. Declare Brave as a separate user-scope role

The Windows application declaration adds `Brave.Brave` version `151.1.93.138` with role `browser-relay` and user scope. Validators require that identity, version, role, and scope. Zen remains the only application with role `browser`.

Brave matches the Darwin relay host and is not in the centrally managed application list. Microsoft Edge is rejected because employer policy owns it. Google Chrome is rejected because the audit assigns it to central management and its executable is currently absent.

The declaration adds no startup resource, default-browser setting, policy file, or extension deployment. Removing the application declaration therefore does not affect Zen or the Linux host.

### 4. Keep the unpacked extension and profile manual

The operator runs `omp browser-relay install --dir` with a directory under the Windows user's local application data. The operator creates one Brave profile named `OMP Relay`, enables developer mode in that profile, and loads the generated directory through `brave://extensions`.

This state remains manual because OMP generates the unpacked extension and Brave owns its profile database. WinGet Configuration installs the browser package only. NixOS activation writes no Windows path.

The relay profile is used only for web interfaces that require interactive login or multi-factor authentication. The operator opens a dedicated tab before the harness adopts it. Ordinary browsing remains in Zen, and the relay profile contains no unrelated tabs.

### 5. Keep relay startup on demand

The configuration does not add a Windows startup entry and does not persist the relay daemon. OMP starts the loopback relay when a relay-backed tool session requests it. The operator opens Brave manually when authentication is required and closes it after the session.

The live check restarts Windows and confirms that neither Brave nor the relay daemon starts automatically. It then opens the dedicated profile, verifies the extension connection, and lets the browser tool adopt one named tab.

## Risks / Trade-offs

- [OMP changes Chromium's ABI] → The live browser smoke fails after the OMP update. Add only the newly required shared-library provider through a reviewed NixOS change.
- [The relay extension can control browser tabs] → Load it only in the dedicated `OMP Relay` profile and keep unrelated tabs out of that profile.
- [Windows-to-WSL loopback forwarding changes] → The relay connection check fails before an authenticated task starts. Keep the daemon on loopback and do not expose a LAN listener.
- [The pinned Brave release becomes unavailable] → Update the declared version and rendered WinGet artifact through the normal dependency review path.
- [A second browser adds maintenance] → Its role is narrow, it does not start automatically, and removal does not affect Zen or headless Chromium.
