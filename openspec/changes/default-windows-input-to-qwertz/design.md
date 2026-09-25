## Context

See `proposal.md` for the defect. On 2026-09-25, the diagnosis on korolev used Word 16.0.20326 with an English UI. Word's automation API (`BuildKeyCode`, `FindKey`) read the key assignments. Separate hidden Word processes tested each session state. The operator's open document was not changed.

The declared `de-DE` entry lists native Neo first and German QWERTZ second. Native Neo is the default input method. Windows loads native Neo first in each session.

The native Neo driver reports each third-layer character with a driver-specific modifier bit (`0x10`). For German QWERTZ, `VkKeyScanEx` returns a number or punctuation key with `Shift` or `AltGr`. For native Neo, it returns a letter key:

| Word shortcut                          | Native Neo key | Word command with native Neo loaded first    | Standard command                   |
| -------------------------------------- | -------------- | -------------------------------------------- | ---------------------------------- |
| `Ctrl+]`                               | C              | `GrowFontOnePoint` on `Ctrl+C`               | `EditCopy`                         |
| `Ctrl+_`                               | V              | nonbreaking hyphen on `Ctrl+V`               | `EditPaste`                        |
| `Ctrl+=`                               | F              | `Subscript` on `Ctrl+F`                      | find                               |
| `Ctrl+[`                               | L              | `ShrinkFontOnePoint` on `Ctrl+L`             | `LeftPara`                         |
| `Ctrl+\`                               | U              | `ToggleMasterSubdocs` on `Ctrl+U`            | `Underline`                        |
| `Ctrl+:`, `Ctrl+~`, `Ctrl+&`, `Ctrl+@` | D, P, Q, Y     | accent prefixes                              | font, print, reset paragraph, redo |
| `Ctrl+>`, `Ctrl+<`                     | G, H           | `GrowFont`, `ShrinkFont` on `Ctrl+Shift+G/H` | word count, hidden text            |

`Normal.dotm` held no custom key assignment. Word generated these assignments itself.

The session state determined the result:

| Session state at Word start                                              | Result               |
| ------------------------------------------------------------------------ | -------------------- |
| German QWERTZ active, native Neo loaded first                            | wrong assignments    |
| Austrian QWERTZ active, native Neo loaded first                          | wrong assignments    |
| German QWERTZ as session default input language, native Neo loaded first | wrong assignments    |
| Native Neo removed from the `Preload` registry value only                | wrong assignments    |
| German QWERTZ moved to the head of the loaded list, QWERTZ active        | standard assignments |
| German QWERTZ moved to the head of the loaded list, native Neo active    | standard assignments |

Word therefore uses the first loaded keyboard layout, not the active layout or its language. A request to list QWERTZ before native Neo while native Neo stayed the default did not persist. Windows restored native Neo to the first `de-DE` position and to `Preload` entry `1`. With QWERTZ as the default, Windows kept QWERTZ first.

ReNeo 1.6.0 identifies native Neo by `kbdneo2.dll` in its `layouts.json`. ReNeo selects standalone or extension mode at launch, at reload, when its hook starts, and at the first key event after a change of foreground window. It does not check the layout after `Win+Space` in the same window ([ReNeo #111](https://github.com/Rojetto/ReNeo/issues/111)).

## Goals / Non-Goals

**Goals:**

- Give Office applications a standard layout as the first loaded keyboard layout at every sign-in.
- Keep Neo typing in ordinary and elevated applications through ReNeo.
- Keep native Neo installed and selectable for UAC and other surfaces that ReNeo cannot reach.

**Non-Goals:**

- Change the sign-in screen layouts under `HKEY_USERS\.DEFAULT`. They stay outside the declaration.
- Remove the native Neo driver or change its Administrator script.
- Override Office shortcuts in application templates.
- Change ReNeo's layout detection.

## Decisions

### Make German QWERTZ the default input method

Windows loads the default input method first, and Office derives character-based shortcuts from that layout. German QWERTZ has no Neo characters on letter keys, so every `Ctrl` letter shortcut keeps its standard command. The measured result holds while native Neo is active.

Alternatives:

- Keep native Neo as the default and list QWERTZ first. Windows restores the default to the first position, so the order does not persist.
- Move QWERTZ to the head of the loaded list at each sign-in with `ActivateKeyboardLayout(..., KLF_REORDER)`. This works in the running session but adds a sign-in race with Office processes that start early. It also repeats a session correction that the declared default already achieves.
- Assign standard commands to the affected keys in `Normal.dotm`. This repairs one application at a time, hides the cause, and leaves Excel and other Office applications affected.
- Remove the native Neo driver. The operator chose to keep native Neo available.

### Replace the native Neo input-method resource

A `german-input-methods` resource replaces `native-neo-input-method`. The name describes its new ownership: the German input-method order and the default. The test requires `0407:00000407` and `0407:b0000407` as the first two `de-DE` tips and the QWERTZ default override. The set script keeps other `de-DE` tips after them. When the tip order changes, the script writes the language list with the existing German placeholder in the empty `en-GB` entry. Windows discards that placeholder, so it adds no UK keyboard. The script keeps the existing native Neo registration guard. It then sets the default override.

### Enable ReNeo standalone mode

With `standaloneMode` set to `true`, ReNeo supplies all Neo layers while German QWERTZ is active. ReNeo recognizes `kbdneo2.dll` and changes to extension mode while native Neo is active. The elevated `RunAs` launcher stays unchanged, so ReNeo continues to reach elevated applications.

### Keep the Administrator boundary

The native Neo script, its DLLs, and its `b0000407` registration do not change. The document registers native Neo but no longer selects it as the default.

## Risks / Trade-offs

- [An Office update changes the source of character-based shortcuts] → The acceptance check records the `FindKey` procedure. Repeat it when Word shortcuts change.
- [UAC prompts accept QWERTZ while QWERTZ is active, including the ReNeo prompt at sign-in] → The operator accepted this trade-off. Select native Neo before a known prompt when Neo input is necessary.
- \[ReNeo keeps its previous mode after `Win+Space` in the same window\] → Change the foreground window once or reload ReNeo from its tray menu.
- [ReNeo does not run] → Windows uses plain QWERTZ. The sign-in launcher and the documented manual launcher command start ReNeo.
- [An unmanaged ReNeo copy runs first] → The launcher exits when any `reneo` process runs. The acceptance check requires the managed package copy.
- [The loaded layout order changes only at the next sign-in] → The acceptance check includes a sign-out and sign-in.

## Migration Plan

1. Build the Windows configuration, run the repository check, and copy the artifacts to `C:\Temp\windows-configuration`.
1. Test and apply the document as the standard Windows user.
1. Sign out and sign in. Accept the ReNeo `RunAs` prompt.
1. Run the acceptance checks in `tasks.md` and record the results in `evidence.md`.

Rollback: revert the change, rebuild, apply the previous document, and sign out and sign in. The previous resource makes native Neo the default again, and Windows moves it to the first position. The previous ReNeo settings disable standalone mode.
