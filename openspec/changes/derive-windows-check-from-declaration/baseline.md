# Windows output baseline

The parent commit is `51272155b87c4b77cf98c2b074e239e4e950f276`.
`flake.lock` SHA-256 is `f0d738d46e2fb144cae9e471f53a89f2c1a4772f9b65cd72f6bb44b983ef2871`.
Two consecutive `nix build .#windows-configuration --no-link --print-out-paths` commands returned the same output:
`/nix/store/sfyngvylyfv8kl7b18dmdr25aqf3bw8j-windows-workstation-configuration`.
The second build reused the output. Thus, each file below had the same SHA-256 on both builds.

| File                           | SHA-256                                                          |
| ------------------------------ | ---------------------------------------------------------------- |
| altsnap-package.json           | 868d51eddc97c86314cc5d169c71261bda0a39f7dd840fcfed9b71338242dd45 |
| altsnap-settings.json          | 574ce4c1b36bedb8ea18ad19eafb59ca8e1e9ec21351e563ecd87cec23689e93 |
| apply-kbdneo.ps1               | 872e36b8c5eefcf8a5b13b94f7aa626cc59a8d1846513b2e0168056835b5e325 |
| apply-zen-policies.ps1         | 0e25199c5dd1e22e37347520ee66f48abf8870520819ce44dca2a690b69e3a6e |
| configuration.winget           | 61691fadb076e0d38c965325fbb93298d5a8197bc73acbd6bdfbbd190f6c7ffd |
| fork-wslgit.json               | 113fca19dbc0948e099e5af1fea859fc72bb437c859fcee1afdebf334e835003 |
| kbdneo.json                    | 8b4f20e2305ea346a13fdbaef5b1e620e22485a24b5272d69f92d535463aac6a |
| power-toys-settings.json       | 1e0b9870a16e54cabbf874aeabebfc7da5adaed2d72a948a4ea1e52f5ef0872d |
| reneo-settings.json            | 47227a71c139b6deb2e51cfa5f80af983f7a4d4d90ce5f1067068d80045e6ce7 |
| start-reneo-elevated.ps1       | 6885707577d59aded209933fdc9fbb2510dab6ef511b8176f62e94fc4fe5dbaf |
| terminal-settings.json         | 23676aaa3fddac50e235291b1fcaf4272c0b8fdef1b7ba430d19262309ba535a |
| zed-catppuccin-theme.json      | 2dccb9fb3ff888e646407b4f84d400304553e0d9a9688ac75d0f9fcd3f8bdf6a |
| zed-keymap.json                | d2fee38c50c624ce07fa50bde1dadc4ad9fc09927ae7e6fb20b4efc1f2e5bd1b |
| zed-settings.json              | f25265765de273f5e57b28b36cc0915efa8ce70524573e2d4e60b326453618f0 |
| zen-catppuccin-logo.svg        | b41be8bf6c8659c532a0b1b984488696073adb31aec7a089211d4f4a7ecd9a83 |
| zen-catppuccin-userChrome.css  | 98ba97510bf2ecd8636686238242cb0f2e43552e2bb93c520818ed89da92189b |
| zen-catppuccin-userContent.css | 297a3c45e624792892482ab45552625b2765e6d44947e878fe5c5731eb7cd44a |
| zen-catppuccin.json            | cd016c8ef9819b46895c33ab47e8196bef87c017f29a81d046432a734ffa7262 |
| zen-policies.json              | 3a46acc9e10964ac66b4fd33d5fb94c9a6a5d9aa0945ec83d72f174e91aae310 |

The built document parses as 46 resources: 8 `Microsoft.WinGet/Package`, 22 `Microsoft.Windows/Registry`, and 16 `Microsoft.DSC.Transitional/WindowsPowerShellScript` resources. These nine resources name dependencies: `fork wslgit`, `zed catppuccin theme`, `zen catppuccin theme`, `reneo elevation launcher`, `windows terminal settings`, `zed keymap`, `zed settings`, `reneo settings`, and `power toys settings`. All dependency values are bare resource names. The built document includes `Ferdium.Ferdium` as a self-updating user package without a startup or profile resource. `zed-keymap.json` contains two `Editor && mode == full` bindings maps: disabled controls first, Windows-first actions second. `zed-settings.json` sets `lsp.texlab.settings.texlab.build.onSave` to `true`. `power-toys-settings.json` enables only `CmdPal`; its other 34 named modules are disabled. The `windows dark appearance` test checks `AppsUseLightTheme = 0`, `SystemUsesLightTheme = 0`, `EnableTransparency = 0`, and the Bloom wallpaper. It does not check the generated active `Custom.theme` path.

The only allowed changes are `configuration.winget` and `zen-catppuccin.json`. The baseline Zen specification contains the following three members; each leaves both Zen document scripts and the JSON review file:

```text
userChrome.css: "sri":"sha256-mLqXUQvy7NhjZoYjgkLLDy5DVS4ruTxSCBjtidqSGJs=",
userContent.css: "sri":"sha256-KXo8ReYkeSiSSCq0VVJiWydl5tRJR+h4/lxXMet81Eo=",
zen-logo.svg: "sri":"sha256-tBvov2yGWcUyoLG5hEiGlgc62zGux6CJIR1PSn7NmoM=",
```

The baseline `fork wslgit` set script has no `Merge-Object` definition. Its branch after `$gitPath = Join-Path $root 'bin\git.exe'` is:

```powershell
if ($null -eq $settings.PSObject.Properties['GitInstancePath']) {
  $settings | Add-Member -NotePropertyName GitInstancePath -NotePropertyValue $gitPath
} else {
  $settings.GitInstancePath = $gitPath
}
```

The permitted replacement prepends the same `Merge-Object` function as `zed settings` and uses `Merge-Object $settings ([PSCustomObject]@{ GitInstancePath = (Join-Path $root 'bin\git.exe') })`. No other parsed YAML value or script byte can change.

The pinned system drvPaths before this change are:

```json
{"korolev":"/nix/store/gm6nyljbwwrlnylcdp6mg0ck2sh65baj-nixos-system-korolev-26.05.20260903.a5cc6f2.drv","macbook-pro":"/nix/store/5yif3pzimw7gk54pxnmz2i9868zrqd9c-darwin-system-26.05.c3e90c8.drv"}
```

They came from `nix eval --impure --json -f /tmp/fleet-drv.nix`, which fixes `system.configurationRevision` for both hosts.

The comparison uses the manifest above. It checks the file set, all 19 baseline hashes, the 17 unchanged files, exact Zen script replacements, the Fork merge replacement, and all remaining parsed YAML values.

```sh
bun openspec/changes/derive-windows-check-from-declaration/compare-baseline.js \
  /nix/store/sfyngvylyfv8kl7b18dmdr25aqf3bw8j-windows-workstation-configuration \
  /nix/store/sfyngvylyfv8kl7b18dmdr25aqf3bw8j-windows-workstation-configuration
```

Baseline self-comparison: `baseline self-comparison: 19 identical files; zero differences`.

After the renderer migration, `nix eval --offline --option allow-import-from-derivation false .#windows-configuration.drvPath` returned `/nix/store/jk37lkwm4wyq9nzgb1nhs93vhnrwa2s3-windows-workstation-configuration.drv`.
The output build returned `/nix/store/smc4vlqga3lvrcpss5f84yq5mn7haxpx-windows-workstation-configuration`.

```sh
bun openspec/changes/derive-windows-check-from-declaration/compare-baseline.js \
  /nix/store/sfyngvylyfv8kl7b18dmdr25aqf3bw8j-windows-workstation-configuration \
  /nix/store/smc4vlqga3lvrcpss5f84yq5mn7haxpx-windows-workstation-configuration
```

The result was `19 files: 17 byte-identical; Zen SRI removal and Fork merge only; no YAML semantic drift`.
The comparison found no new or missing files.
The declaration has ten roles, ten applications, and sixteen review files.
It contains no release fields or Nix store paths.

For an exact-pin probe, Fork changed from `2.21.0` to `2.21.1`.
Only `configuration.winget` changed; its package selector and application metadata both changed.
The packaged checker accepted the probed output and its matching declaration without a checker edit.
An exact `editor` policy with version `1.0.0` still rendered and produced `application editor: forbidden exact policy`.
Removing AltSnap also rendered and produced `application window-tool: declared role has no application`.
Both probes were reverted; another build returned the unchanged migrated output path.

The `psHereString` probe returned `{"success":false,"value":false}` for a line equal to `'@`.
The `psJson` probe rendered `'{"label":"O''Brien"}'`.
PowerShell 7 parsed it, converted it from JSON, and printed `O'Brien` with exit status 0.

The packaged check build ran eleven `unittest` methods and passed.
The packaged CLI returned exit 0 without output for the migrated output and serialized declaration.
The Darwin flake check also passed.
With an exact `editor` policy, the renderer still built.
The Darwin flake check failed with `windows-configuration-check: application editor: forbidden exact policy`.
The Linux check derivation evaluated to `/nix/store/c116lz1ix50g39bl3v76a9lpcpv03j1j-check-windows-configuration.drv`.
It was not built on this Mac.

Six temporary validator mutations each made the corresponding fixture method fail.
Disabled `validate_declaration`, `validate_files`, `validate_document`, `validate_applications`, `validate_boundaries`, and `parse_scripts` produced 7, 1, 4, 9, 4, and 6 failures or errors respectively.
After restoring those functions, the package build ran all eleven tests and passed.

The final Mac gates passed:

| Command                                                            | Result                                                                                                                            |
| ------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------- |
| `nix fmt -- --fail-on-change`                                      | Passed after the first run formatted eight task-owned files. The second run changed no files.                                     |
| `nix flake check --print-build-logs`                               | Passed the Darwin checks, including eleven checker tests, `windowsConfiguration`, and treefmt. Linux was omitted as incompatible. |
| `nix run .#check-darwin-build-plans`                               | Passed: 43 outputs, none reaching a forbidden source build.                                                                       |
| `nix build .#darwinConfigurations.macbook-pro.system --no-link`    | Passed.                                                                                                                           |
| `openspec validate derive-windows-check-from-declaration --strict` | Passed: the change is valid.                                                                                                      |

The final Windows build returned `/nix/store/smc4vlqga3lvrcpss5f84yq5mn7haxpx-windows-workstation-configuration` again.
Its final comparison reported 17 identical files and only the allowed Fork and Zen changes.

The pinned system drvPaths after this change were unchanged:

```json
{"korolev":"/nix/store/gm6nyljbwwrlnylcdp6mg0ck2sh65baj-nixos-system-korolev-26.05.20260903.a5cc6f2.drv","macbook-pro":"/nix/store/5yif3pzimw7gk54pxnmz2i9868zrqd9c-darwin-system-26.05.c3e90c8.drv"}
```

The Windows live gate remains an owner action. No Windows resource was applied from this Mac.
