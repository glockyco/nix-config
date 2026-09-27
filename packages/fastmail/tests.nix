{ fastmail, runCommand }:

runCommand "check-fastmail-command" { } ''
  missing="$PWD/missing-token"
  status=0
  ${fastmail}/bin/fastmail --token-file "$missing" mailboxes >stdout 2>stderr || status=$?
  test "$status" -eq 1
  test ! -s stdout
  grep -F "fastmail: cannot read token from $missing:" stderr
  test "$(wc -l < stderr)" -eq 1
  touch "$out"
''
