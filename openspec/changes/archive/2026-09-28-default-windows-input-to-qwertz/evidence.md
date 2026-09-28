# Evidence

## Diagnosis on 2026-09-25

Host: korolev, Word 16.0.20326, English UI, `Normal.dotm` with zero custom key bindings. Word's automation API read the assignments with `FindKey(BuildKeyCode(wdKeyControl, <key>))`. Separate hidden `Word.Application` automation processes tested each session state. The operator's open document stayed unchanged.

In the operator's Word process, the main window used HKL `f0c00407` (native Neo). The observed assignments were `Ctrl+C` `GrowFontOnePoint`, `Ctrl+V` a symbol (category 6), `Ctrl+F` `Subscript`, `Ctrl+L` `ShrinkFontOnePoint`, `Ctrl+U` `ToggleMasterSubdocs`, and prefix keys on `Ctrl+D`, `Ctrl+P`, `Ctrl+Q`, and `Ctrl+Y`. `Ctrl+Shift+G` and `Ctrl+Shift+H` were `GrowFont` and `ShrinkFont`.

`VkKeyScanExW` for HKL `f0c00407` returned letter keys with modifier bits `0x10` for `[ ] \ = _ : ~ & @ < >`: L, C, U, F, V, D, P, Q, Y, H, G. For HKL `04070407`, the same characters were on number or punctuation keys with `Shift` or `Ctrl+Alt`.

| State of the fresh Word process at start                                    | `Ctrl+C`           |
| --------------------------------------------------------------------------- | ------------------ |
| Operator restart with German QWERTZ active and ReNeo closed                 | `GrowFontOnePoint` |
| German QWERTZ active, native Neo first in `GetKeyboardLayoutList`           | `GrowFontOnePoint` |
| Session default input language set to QWERTZ with `SPI_SETDEFAULTINPUTLANG` | `GrowFontOnePoint` |
| Austrian QWERTZ (`04070c07`) active                                         | `GrowFontOnePoint` |
| `Preload` without native Neo, loaded list unchanged                         | `GrowFontOnePoint` |
| `ActivateKeyboardLayout(04070407, KLF_REORDER)`, QWERTZ active              | `EditCopy`         |
| Same order, native Neo active                                               | `EditCopy`         |

With QWERTZ first and native Neo active, `Ctrl+V`, `F`, `L`, `U`, `D`, `P`, `Q`, `Y`, and `Z` gave `EditPaste`, `SmartFind`, `LeftPara`, `Underline`, `FormatFont`, `PrintPreviewAndPrint`, `ResetPara`, `EditRedoOrRepeat`, and `EditUndo`.

A request for `de-DE` tips QWERTZ then native Neo, with native Neo as the default override, did not persist. After 20 seconds, the list and `Preload` still showed native Neo first.

During the diagnosis, the input-method list and default were changed and restored several times. One script defect removed the German QWERTZ tip for about one minute. The final restore was verified against the original list, default, and `Preload`.

## Apply on 2026-09-25

Revision `de56a74`. Artifacts copied to `C:\Temp\windows-configuration`.

`winget configure test` before the apply reported drift on `german input methods`, `reneo settings`, `package browser`, and `fork wslgit`. The last two are outside this change. Zen had updated itself to `1.22.2b` against the exact pin `1.21.16b`. The `sh.exe` and `bash.exe` copies of `wsl.exe` were older than the installed WSL.

A full document apply would downgrade Zen. The operator selected the rendered set scripts for `german input methods`, `reneo settings`, and `fork wslgit` instead. The first wslgit run failed because six `wslgit\bin\git.exe` fetch and push processes from Fork had been hung since 2026-09-23 and 2026-09-24. They were stopped, and the second run completed.

After the apply, `winget configure test` reported drift only on `package browser`. The persisted state was `en-GB=[]`, `de-DE=[0407:00000407,0407:B0000407]`, `de-AT=[0C07:00000407]`, override `0407:00000407`, and `Preload` `1=00000407 2=d0010407 3=00000c07`. The managed ReNeo `config.json` had `standaloneMode` `true`.

## After sign-in on 2026-09-25

The operator signed out, signed in, and accepted the ReNeo `RunAs` prompt. `GetKeyboardLayoutList` returned `04070407,f0c00407,04070c07`. One `reneo.exe` ran; its elevated token hid the executable path from the standard session, and no Desktop copy had a startup entry. A fresh Word automation process with QWERTZ active returned `EditCopy`, `EditPaste`, `SmartFind`, `LeftPara`, `Underline`, `FormatFont`, `PrintPreviewAndPrint`, `ResetPara`, and `EditRedoOrRepeat` for `Ctrl+C`, `V`, `F`, `L`, `U`, `D`, `P`, `Q`, and `Y`. The operator confirmed that `Ctrl+C` and `Ctrl+V` work in Word.

## Operator acceptance on 2026-09-28

The Windows state was the one applied from `de56a74`. Its rebased equivalent on `main` is `7f7f1ed`, which renders the same input-method and ReNeo settings from declaration data. Word 16.0.20326, ReNeo 1.6.0 (the pinned `Rojetto.ReNeo.neo2`). The operator reported these results:

- With QWERTZ active, copy and paste with `Ctrl+C` and `Ctrl+V` work in Word and Excel.
- After switching to native Neo with `Win+Space`, Word's standard `Ctrl` shortcuts still work.
- In Notepad with QWERTZ active, ReNeo supplies Neo layer 1 (physical `A` gives `u`) and layer 3 (`Q W E R T` gives `… _ [ ] ^`, `A S D F` gives `\ / { }`). Layer 4 on physical `A S D F G` moves the cursor as Home, ←, ↓, →, End, and layers 5 and 6 give Greek and math symbols.
- In Notepad started as Administrator, the same layers work.
- The UAC credential prompt behaved as specified: with QWERTZ active it accepted plain QWERTZ input, and with native Neo active it accepted the native Neo base layout. ReNeo layers do not reach the secure desktop.
