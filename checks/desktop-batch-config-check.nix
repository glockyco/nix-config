{
  python3,
  openssh,
  runCommand,
  renderedHome,
  host,
}:
runCommand "check-${host.name}-desktop-batch-configuration"
  {
    nativeBuildInputs = [
      python3
      openssh
    ];
  }
  ''
    python ${./chezmoi-ssh-check.py} ${renderedHome} ${host.name} desktop
    touch "$out"
  ''
