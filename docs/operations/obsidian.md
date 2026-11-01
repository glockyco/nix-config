# Obsidian

Obsidian holds the notes vault on the Mac and Korolev. The Mac installs it from the Homebrew cask in its [application record](../../home/.chezmoidata/hosts.toml), and Korolev installs the WinGet package from its [declaration](../../windows/workstation.json). Obsidian updates itself. Its account, vaults, Sync connection, settings and plugins belong to Obsidian, so neither activation nor apply changes them.

Both machines start Obsidian at sign-in, because Sync runs only while Obsidian runs. The Mac starts it only for a graphical login, so an SSH login leaves it closed.

## Git

Both machines keep a Git clone of the vault, `~/notes` on the Mac and `~/src/github.com/glockyco/notes` on Korolev, with `https://github.com/glockyco/notes.git` as origin. Obsidian Sync carries edits between them, so a change can reach both clones. Pull with rebase before committing, which drops a change upstream already has. The vault's pre-commit hook scans for secrets with gitleaks through lefthook, which both machines install.

Obsidian Sync does not carry dotfiles, so turn a synced folder into a clone in place:

```sh
cd ~/notes
git init -b main
git remote add origin https://github.com/glockyco/notes.git
git fetch origin
git reset origin/main
git branch --set-upstream-to=origin/main main
git checkout -- .gitignore .gitattributes .lefthook.yml .archive
lefthook install
```

`git status` then lists only the edits Sync brought that upstream lacks.

## Command line

The `obsidian` command talks to the running app and works only after its command-line interface is turned on. Turn it on once on each machine:

1. Open Obsidian's settings, select General and turn on Command line interface in the Advanced section.
1. In the dialog that offers to register `obsidian` in PATH, choose Skip. The configuration already puts the command on PATH, and on the Mac the registration asks for Administrator rights to create a second link outside the configuration.
1. In a new terminal, check that `obsidian version` prints Obsidian's version.

On Korolev, `obsidian` in a terminal resolves to the `Obsidian.com` terminal redirector beside the app's `Obsidian.exe`, because PATHEXT lists `.COM` first. Programs that look commands up through Bun's `Bun.which`, such as OMP, get `Obsidian.exe` instead. It answers command-line requests too when its output goes to a pipe, as it does for OMP's `vault://`.
