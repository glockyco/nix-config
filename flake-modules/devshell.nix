{ config, inputs, ... }:
let
  hosts = builtins.attrValues config.fleet.hosts;
in
{
  perSystem =
    {
      config,
      lib,
      pkgs,
      system,
      ...
    }:
    let
      hasDarwinHost = lib.any (host: host.system == system && host.kind == "darwin") hosts;
    in
    {
      # Declared for every system, with no platform condition. `.envrc` and
      # `lefthook.yml` both enter this shell, and the shell is what installs
      # the commit hook, so a system without it has no local gate.
      devShells.default = pkgs.mkShellNoCC {
        packages = [
          pkgs.git
          pkgs.lefthook

          # The commit hook runs this wrapper through `nix develop`, and
          # `nix fmt` and `checks.treefmt` run the same one.
          config.treefmt.build.wrapper

          # The interpreter comes from the pinned nixpkgs, and every
          # consumer names it independently: this shell, the `fastmail`
          # wrapper and the apple-terminal activation script. The shell
          # has to name it too rather than inherit one, because an
          # undeclared `python3` resolves to macOS's 3.9, which cannot
          # parse the `X | None` annotations these scripts use and fails
          # in a way that reads like a code bug.
          pkgs.python3
        ]
        # Host tools, not repository tools. `darwin-rebuild` activates the
        # Darwin host, and `dnsconfig.js` needs the credential that
        # chezmoi decrypts locally into ~/.config/credentials/. The WSL
        # host declares no secret, so shipping `dnscontrol` there would move
        # the failure from shell entry into the middle of a DNS operation.
        ++ lib.optionals hasDarwinHost [
          inputs.nix-darwin.packages.${system}.darwin-rebuild
          pkgs.dnscontrol
        ];

        # Install the commit hook on entry. The grep keeps this cheap on
        # re-entry, and it also catches a hook file left behind by a
        # previous runner: that file does not mention lefthook, so
        # `--force` replaces it.
        shellHook = ''
          if ! grep -qs lefthook .git/hooks/pre-commit; then
            ${lib.getExe pkgs.lefthook} install --force >/dev/null
          fi
        '';
      };
    };
}
