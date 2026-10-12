{
  python3,
  openssh,
  runCommand,
  renderedHome,
  host,
  # A Windows endpoint name from the ssh chezmoi data, such as desktop or korolev.
  endpoint,
}:
runCommand "check-${host.name}-${endpoint}-batch-configuration"
  {
    nativeBuildInputs = [
      python3
      openssh
    ];
  }
  ''
    python ${./chezmoi-ssh-check.py} ${renderedHome} ${host.name} ${endpoint}
    touch "$out"
  ''
