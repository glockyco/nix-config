{
  coreutils,
  findutils,
  gnugrep,
  gnused,
  writeShellApplication,
}:

writeShellApplication {
  name = "module-imports-check";

  runtimeInputs = [
    coreutils
    findutils
    gnugrep
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

        for module in "$dir"/*.nix; do
          name=$(basename "$module")

          if [ "$name" != default.nix ]; then
            # Drop line comments before matching. A commented-out import used to
            # satisfy the rule, which turned "someone disabled this module" into
            # a silent pass.
            sed 's/#.*//' "$default" | grep -qF "./$name" ||
              printf '%s\n' "''${module#./}"
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
