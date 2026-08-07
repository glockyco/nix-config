{
  # CrossOver requires Rosetta 2 for its x86_64 wineloader.
  # `--agree-to-license` accepts Apple's licence non-interactively.
  # Guard on `oahd` to avoid repeat installs; keep failures non-fatal.
  system.activationScripts.extraActivation.text = ''
    if ! /usr/bin/pgrep -q oahd; then
      echo "installing Rosetta 2..." >&2
      /usr/sbin/softwareupdate --install-rosetta --agree-to-license \
        || echo "warning: Rosetta 2 installation failed" >&2
    fi
  '';
}
