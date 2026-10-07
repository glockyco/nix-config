{
  python3,
  runCommand,
  age,
  chezmoi,
}:
runCommand "check-secret-encryption"
  {
    nativeBuildInputs = [
      python3
      age
      chezmoi
    ];
  }
  ''
    python ${./.}/secret-encryption-tests.py
    python ${./secret-encryption-check.py} ${../home}
    export HOME="$TMPDIR/home"
    export XDG_CONFIG_HOME="$HOME/.config"
    export XDG_CACHE_HOME="$HOME/.cache"
    export XDG_DATA_HOME="$HOME/.local/share"
    export XDG_STATE_HOME="$HOME/.local/state"
    mkdir -p "$HOME" source/home/dot_config/private_credentials source/home/.chezmoidata
    umask 077
    age-keygen -o "$TMPDIR/identity" 2>/dev/null
    recipient="$(age-keygen -y "$TMPDIR/identity")"
    printf 'synthetic credential\n' > "$TMPDIR/plaintext"
    for name in fastmail-token cloudflare-dns-token cloudflare-workers-token; do
      age -r "$recipient" -o "source/home/dot_config/private_credentials/encrypted_private_$name.age" "$TMPDIR/plaintext"
    done
    cp ${../home/.chezmoidata/credentials.toml} source/home/.chezmoidata/credentials.toml
    python ${./secret-encryption-check.py} source/home
    printf 'home\n' > source/.chezmoiroot
    cat > "$TMPDIR/age.toml" <<EOF
    sourceDir = "$PWD/source"
    encryption = "age"
    useBuiltinAge = true
    [age]
    identity = "$TMPDIR/identity"
    recipient = "$recipient"
    EOF
    # Chezmoi must decrypt with its built-in implementation, not system age.
    mkdir "$TMPDIR/failing-age"
    cat > "$TMPDIR/failing-age/age" <<'SH'
    #!/bin/sh
    echo "external age must not be invoked by chezmoi" >&2
    exit 97
    SH
    chmod +x "$TMPDIR/failing-age/age"
    age_path="$PATH"
    export PATH="$TMPDIR/failing-age:$PATH"
    chezmoi --config "$TMPDIR/age.toml" --no-tty apply
    for name in fastmail-token cloudflare-dns-token cloudflare-workers-token; do
      cmp "$TMPDIR/plaintext" "$HOME/.config/credentials/$name"
      test "$(stat -c %a "$HOME/.config/credentials/$name" 2>/dev/null || stat -f %Lp "$HOME/.config/credentials/$name")" = 600
    done
    test "$(stat -c %a "$HOME/.config/credentials" 2>/dev/null || stat -f %Lp "$HOME/.config/credentials")" = 700
    chezmoi --config "$TMPDIR/age.toml" --no-tty verify
    chezmoi --config "$TMPDIR/age.toml" --no-tty apply
    for scope in dns workers; do
      chezmoi --config "$TMPDIR/age.toml" execute-template --file \
        ${../home}/dot_config/direnv/lib/use_cloudflare_$scope.sh.tmpl \
        --output "$TMPDIR/helper.sh"
      log_error() { printf '%s\n' "$*" >&2; }
      source "$TMPDIR/helper.sh"
      use_cloudflare_$scope
      test "$CLOUDFLARE_API_TOKEN" = "$(cat "$TMPDIR/plaintext")"
      mv "$HOME/.config/credentials/cloudflare-$scope-token" "$TMPDIR/credential"
      if use_cloudflare_$scope 2>"$TMPDIR/missing.log"; then
        echo "missing credential was accepted" >&2
        exit 1
      fi
      test -s "$TMPDIR/missing.log"
      mv "$TMPDIR/credential" "$HOME/.config/credentials/cloudflare-$scope-token"
      unset CLOUDFLARE_API_TOKEN
    done
    export PATH="$age_path"
    # Both supported encodings are validated against actual synthetic age output.
    age -a -r "$recipient" -o "$TMPDIR/armored.age" "$TMPDIR/plaintext"
    python - "$TMPDIR/armored.age" ${./secret-encryption-check.py} <<'PY'
    import importlib.util
    import sys
    from pathlib import Path
    spec = importlib.util.spec_from_file_location("validator", sys.argv[2])
    validator = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(validator)
    assert validator.valid_age(Path(sys.argv[1]).read_bytes())
    PY
    touch "$out"
  ''
