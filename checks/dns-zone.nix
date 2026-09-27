{
  dnscontrol,
  runCommand,
}:

# `dnscontrol check` validates the zone without provider access or a token.
# It prints a warning such as inconsistent RRset TTLs and still exits 0, so the
# check accepts only the exact clean report and fails on any other line.
runCommand "check-dns-zone" { nativeBuildInputs = [ dnscontrol ]; } ''
  cp ${../dns/dnsconfig.js} dnsconfig.js
  cp ${../dns/creds.json} creds.json
  unset CLOUDFLARE_API_TOKEN
  export HOME="$TMPDIR/home"
  mkdir -p "$HOME"

  status=0
  dnscontrol check > report 2>&1 || status=$?
  if [ "$status" -ne 0 ] || [ "$(grep -v '^$' report)" != "No errors." ]; then
    cat report >&2
    echo "dns-zone: DNSControl reported a finding (exit $status)" >&2
    exit 1
  fi
  touch "$out"
''
