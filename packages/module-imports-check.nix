{
  coreutils,
  findutils,
  gnused,
  writeShellApplication,
}:

writeShellApplication {
  name = "module-imports-check";

  runtimeInputs = [
    coreutils
    findutils
    gnused
  ];

  text = ''
    # An unimported module is absent rather than an error, so a module that no
    # sibling `default.nix` imports is silently dead. Reject that.
    #
    # The search covers every directory that holds a `default.nix`, because the
    # tree nests: a platform subdirectory carries its own import list.
    #
    # The rule is deliberately local. It asserts that a module has an import in
    # its own directory's list, and it does not assert that something imports
    # the directory itself. A host selects directories, so that relationship
    # lives outside this rule.
    root=''${1:-}

    if [ -z "$root" ]; then
      echo "usage: module-imports-check <module-root>" >&2
      exit 2
    fi

    cd "$root"

    # The pipeline writes to standard output rather than to a variable, so the
    # subshell that `while` runs in cannot lose the result.
    unimported=$(
      find . -type f -name default.nix | sort | while IFS= read -r default; do
        dir=$(dirname "$default")

        # Read the list once per directory, with line comments removed. A
        # commented-out import must not satisfy the rule, because that turns
        # "someone disabled this module" into a silent pass.
        #
        # The match is a shell pattern rather than a pipe into `grep -q`.
        # `grep -q` exits at its first match, which can leave the producer in
        # the pipe holding unwritten output; it then takes SIGPIPE, and
        # `pipefail` reports the whole pipeline as failed. That would report an
        # imported module as missing once a list outgrew the pipe buffer.
        imports=$(sed 's/#.*//' "$default")

        for module in "$dir"/*.nix; do
          name=$(basename "$module")

          if [ "$name" != default.nix ]; then
            case "$imports" in
              *"./$name"*) ;;
              *) printf '%s\n' "''${module#./}" ;;
            esac
          fi
        done
      done
    )

    if [ -n "$unimported" ]; then
      echo "modules with no import in their sibling default.nix:" >&2
      printf '%s\n' "$unimported" >&2
      exit 1
    fi
  '';
}
