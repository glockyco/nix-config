{ lib, writeShellApplication }:

writeShellApplication {
  name = "rosetta";
  meta = {
    description = "Install Rosetta when x86_64 execution is unavailable";
    mainProgram = "rosetta";
    platforms = lib.platforms.darwin;
  };
  text = ''
    if [ "$#" -ne 0 ]; then
      printf '%s\n' 'usage: rosetta' >&2
      exit 2
    fi

    arch_command=''${ROSETTA_ARCH:-/usr/bin/arch}
    softwareupdate_command=''${ROSETTA_SOFTWAREUPDATE:-/usr/sbin/softwareupdate}

    if "$arch_command" -arch x86_64 /usr/bin/true; then
      printf '%s\n' 'rosetta: current: x86_64 execution works' >&2
      exit 0
    fi

    if "$softwareupdate_command" --install-rosetta --agree-to-license; then
      printf '%s\n' 'rosetta: changed: installed Rosetta' >&2
    else
      status=$?
      printf '%s\n' 'rosetta: Rosetta installation failed' >&2
      exit "$status"
    fi
  '';
}
