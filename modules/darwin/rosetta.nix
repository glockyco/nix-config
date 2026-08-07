{
  # Rosetta 2, needed because CrossOver 26 still ships an x86_64 wineloader.
  #
  # `--agree-to-license` accepts Apple's licence non-interactively. That is a
  # deliberate choice recorded here rather than a prompt at activation time.
  #
  # Guarded on oahd so it runs once, and non-fatal so a failed download cannot
  # break a switch.
  system.activationScripts.extraActivation.text = ''
    if ! /usr/bin/pgrep -q oahd; then
      echo "installing Rosetta 2..." >&2
      /usr/sbin/softwareupdate --install-rosetta --agree-to-license \
        || echo "warning: Rosetta 2 installation failed" >&2
    fi
  '';
}
