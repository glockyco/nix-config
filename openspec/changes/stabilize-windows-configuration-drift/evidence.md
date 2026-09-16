## Windows convergence evidence

Recorded on 2026-09-16 at 13:55 CEST on the Windows work machine.

### Reviewed input

- Windows configuration artifact: `/nix/store/h8jbc7830b530ck8gm9hv4837l7nca1d-windows-workstation-configuration`
- Windows staging directory: `C:\Temp\windows-configuration-reviewed-3b316e1`
- WinGet version: `v1.29.290`
- Zed keymap revision: `488933d772893f4390e48c5cb3ae7734919cbf70`
- Drift-policy revision: `3b316e1a92da4c30577d01da8ad34aa6288d297a`

### Application versions

| Application | Installed before apply | Installed after apply | WinGet catalog |
| ----------- | ---------------------- | --------------------- | -------------- |
| Zed         | `1.19.2`               | `1.19.2`              | `1.19.2`       |
| Brave       | `153.1.95.101`         | `153.1.95.101`        | `152.1.94.121` |

The apply did not install the former declared versions, Zed `1.18.0` or Brave `152.1.94.119`. It did not downgrade Brave to the older catalog version.

### Pre-apply test

`winget configure test` reported every resource in the desired state except `zed keymap`. In particular, `package editor`, `package browser relay`, and `windows dark appearance` reported the desired state. The command exited 1 because the committed keymap had not been applied.

### Apply and post-apply tests

`winget configure` applied the complete reviewed document successfully. A subsequent `winget configure test` reported every document resource in the desired state and exited 0.

The elevated `apply-kbdneo.ps1 -Test` command exited 0. The first elevated `apply-zen-policies.ps1 -Test` command reported `Zen policies: drift`; this Administrator-owned artifact is outside the WinGet document. Applying the reviewed Zen policy script and repeating its `-Test` command produced exit 0.
