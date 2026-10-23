# Obsidian

Obsidian holds the notes vault on the Mac and Korolev. The Mac installs it from the Homebrew cask in its [application record](../../home/.chezmoidata/hosts.toml), and Korolev installs the WinGet package from its [declaration](../../windows/workstation.json). Obsidian updates itself. Its account, vaults, Sync connection, settings and plugins belong to Obsidian, so neither activation nor apply changes them.

Both machines start Obsidian at sign-in, because Sync runs only while Obsidian runs. The Mac starts it only for a graphical login, so an SSH login leaves it closed.

## Command line

The `obsidian` command talks to the running app and works only after its command-line interface is turned on. Turn it on once on each machine:

1. Open Obsidian's settings, select General and turn on Command line interface in the Advanced section.
1. In the dialog that offers to register `obsidian` in PATH, choose Skip. The configuration already puts the command on PATH, and on the Mac the registration asks for Administrator rights to create a second link outside the configuration.
1. In a new terminal, check that `obsidian version` prints Obsidian's version.

On Korolev, `obsidian` resolves to the `Obsidian.com` terminal redirector beside the app's `Obsidian.exe`, because PATHEXT lists `.COM` first. Bun's `Bun.which` returns `Obsidian.exe` instead, so a program that resolves commands through it, such as OMP, must call `Obsidian.com` by name.
