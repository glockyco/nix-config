{
  coreutils,
  moduleImportsCheck,
  runCommand,
}:

runCommand "check-module-imports-command"
  {
    nativeBuildInputs = [ coreutils ];
  }
  ''
    check=${moduleImportsCheck}/bin/module-imports-check

    # An empty result only means something when the check can also reject. Each
    # fixture below states one expectation, and the accepted fixture covers the
    # cases that must not raise a false failure.

    accepted=$TMPDIR/accepted
    mkdir -p "$accepted/nested"
    printf '{ imports = [ ./portable.nix ]; }\n' > "$accepted/default.nix"
    printf '{ }\n' > "$accepted/portable.nix"
    printf '{ imports = [ ./platform.nix ]; }\n' > "$accepted/nested/default.nix"
    printf '{ }\n' > "$accepted/nested/platform.nix"

    # A data file beside a module is not a module, so it needs no import.
    printf 'print("data")\n' > "$accepted/nested/helper.py"

    "$check" "$accepted"
    echo 'accepted fixture: passed'

    # A module inside a nested directory that its own list omits. The previous
    # check read one directory level, so this case escaped it.
    rejected_nested=$TMPDIR/rejected-nested
    mkdir -p "$rejected_nested/nested"
    printf '{ imports = [ ./portable.nix ]; }\n' > "$rejected_nested/default.nix"
    printf '{ }\n' > "$rejected_nested/portable.nix"
    printf '{ imports = [ ]; }\n' > "$rejected_nested/nested/default.nix"
    printf '{ }\n' > "$rejected_nested/nested/platform.nix"

    if output=$("$check" "$rejected_nested" 2>&1); then
      echo 'rejected nested fixture: the check accepted an unimported nested module' >&2
      exit 1
    fi

    case "$output" in
      *nested/platform.nix*) ;;
      *)
        echo "rejected nested fixture: the message did not name the module: $output" >&2
        exit 1
        ;;
    esac
    echo 'rejected nested fixture: failed as required'

    # The original one-level behaviour must survive the extension.
    rejected_root=$TMPDIR/rejected-root
    mkdir -p "$rejected_root"
    printf '{ imports = [ ]; }\n' > "$rejected_root/default.nix"
    printf '{ }\n' > "$rejected_root/portable.nix"

    if "$check" "$rejected_root" 2>/dev/null; then
      echo 'rejected root fixture: the check accepted an unimported top-level module' >&2
      exit 1
    fi
    echo 'rejected root fixture: failed as required'

    # A commented-out import must not satisfy the rule. Matching the raw file
    # accepted this, so disabling a module read as importing it.
    rejected_comment=$TMPDIR/rejected-comment
    mkdir -p "$rejected_comment"
    printf '{\n  imports = [\n    # ./portable.nix\n  ];\n}\n' > "$rejected_comment/default.nix"
    printf '{ }\n' > "$rejected_comment/portable.nix"

    if output=$("$check" "$rejected_comment" 2>&1); then
      echo 'rejected comment fixture: the check accepted a commented-out import' >&2
      exit 1
    fi

    case "$output" in
      *portable.nix*) ;;
      *)
        echo "rejected comment fixture: the message did not name the module: $output" >&2
        exit 1
        ;;
    esac
    echo 'rejected comment fixture: failed as required'

    # A missing argument is a usage error rather than a silent pass.
    if "$check" 2>/dev/null; then
      echo 'usage fixture: the check accepted a missing module root' >&2
      exit 1
    fi
    echo 'usage fixture: failed as required'

    touch $out
  ''
