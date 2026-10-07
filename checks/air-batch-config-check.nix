{
  python3,
  openssh,
  runCommand,
  renderedHome,
  host,
}:
runCommand "check-${host.name}-air-batch-configuration"
  {
    nativeBuildInputs = [
      python3
      openssh
    ];
  }
  ''
    python ${./chezmoi-ssh-check.py} ${renderedHome} ${host.name} air
    touch "$out"
  ''
