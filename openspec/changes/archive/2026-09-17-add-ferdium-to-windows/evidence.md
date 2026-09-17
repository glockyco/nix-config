## Windows Ferdium acceptance evidence

Recorded on 2026-09-17 at 08:04 CEST on the Windows work machine.

### Reviewed input

- Windows configuration artifact: `/nix/store/gkmzphccib6lan4m5fa274i6j2ysrabq-windows-workstation-configuration`
- Windows staging directory: `C:\Temp\windows-configuration-ferdium-e15c1f8`
- Applied implementation revision: `e15c1f8`
- WinGet version: `v1.29.290`

### Initial state

`winget list --id Ferdium.Ferdium --exact` found no installed package. The following user paths were absent:

- `%APPDATA%\Ferdium`
- `%LOCALAPPDATA%\Ferdium`
- `%LOCALAPPDATA%\Programs\Ferdium`
- `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\Ferdium.lnk`

No Ferdium process or `HKCU\Software\Microsoft\Windows\CurrentVersion\Run\Ferdium` value existed. The WinGet catalog offered Ferdium `7.2.3`.

The pre-apply `winget configure test` command reported only `package communication client` outside the desired state and exited 1. All other document resources reported the desired state. The elevated `apply-kbdneo.ps1 -Test` and `apply-zen-policies.ps1 -Test` commands both exited 0.

### Apply and package state

`winget configure` applied the complete document as the standard Windows user and exited 0. The `package communication client` resource displayed no elevation shield. The package installed under the interactive user's profile.

| Item                   | Value                                                        |
| ---------------------- | ------------------------------------------------------------ |
| Package identifier     | `Ferdium.Ferdium`                                            |
| WinGet catalog version | `7.2.3`                                                      |
| Installed version      | `7.2.3`                                                      |
| Executable             | `C:\Users\jglock\AppData\Local\Programs\Ferdium\Ferdium.exe` |

The first post-apply `winget configure test` command reported every document resource in the desired state and exited 0. Both elevated Administrator-script tests also exited 0.

### Native launch and application-owned settings

Ferdium launched as a native Windows process from the installed executable. No WSLg process was involved. The fresh sign-in screen remained unauthenticated, and no service was added.

The user opened the actual Ferdium settings UI and confirmed these fresh-profile values:

- Automatic updates: enabled
- Launch at sign-in: disabled

The generated `%APPDATA%\Ferdium\config\settings.json` file also contained `automaticUpdates: true` and `autoLaunchOnStart: false`.

### Reapply and sign-in behavior

After Ferdium closed normally, the settings file had this SHA-256 checksum:

```text
98b9d75d2eb2a79330a2cd4006de84f1c15067ea6423ada74b4a3e0adc0f91ff
```

A second complete `winget configure` apply exited 0. The following test again reported every resource in the desired state and exited 0. Ferdium did not launch during either operation. The settings checksum remained byte-identical.

Ferdium's installer had created this application-owned Run value:

```text
"C:\Users\jglock\AppData\Local\Programs\Ferdium\Ferdium.exe"
```

No `StartupApproved\Run\Ferdium` value or Startup-folder shortcut existed. After the user signed out and signed back in, Ferdium did not start. This observed behavior matched the disabled application preference.
