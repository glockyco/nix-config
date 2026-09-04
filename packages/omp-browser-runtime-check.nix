{
  closureInfo,
  coreutils,
  gnugrep,
  personalOmp,
  runCommand,
  systemPath,
}:

let
  browserLibraries = [
    "libX11.so.6"
    "libXcomposite.so.1"
    "libXdamage.so.1"
    "libXext.so.6"
    "libXfixes.so.3"
    "libXrandr.so.2"
    "libasound.so.2"
    "libatk-1.0.so.0"
    "libatk-bridge-2.0.so.0"
    "libatspi.so.0"
    "libcairo.so.2"
    "libcups.so.2"
    "libdbus-1.so.3"
    "libexpat.so.1"
    "libgbm.so.1"
    "libgio-2.0.so.0"
    "libglib-2.0.so.0"
    "libgobject-2.0.so.0"
    "libnspr4.so"
    "libnss3.so"
    "libnssutil3.so"
    "libpango-1.0.so.0"
    "libsmime3.so"
    "libudev.so.1"
    "libxcb.so.1"
    "libxkbcommon.so.0"
  ];
  wrapperClosure = closureInfo { rootPaths = [ personalOmp ]; };
in
runCommand "check-omp-browser-runtime"
  {
    nativeBuildInputs = [
      coreutils
      gnugrep
    ];
  }
  ''
    library_path=${systemPath}/share/nix-ld/lib

    for library in ${builtins.concatStringsSep " " browserLibraries}; do
      if [ ! -e "$library_path/$library" ]; then
        echo "OMP browser runtime library is missing: $library" >&2
        exit 1
      fi
    done

    if grep -E '/[^/]*(chrome|chromium)[^/]*/' ${wrapperClosure}/store-paths; then
      echo 'The OMP wrapper closure contains a Nix-packaged browser' >&2
      exit 1
    fi

    touch "$out"
  ''
