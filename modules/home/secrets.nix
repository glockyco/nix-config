{ config, inputs, ... }:

{
  # Secrets are committed encrypted and decrypted on this machine at login.
  #
  # The Home Manager port is the right one here: these secrets belong to the
  # user and are read by user processes, so they are installed by a launchd
  # *agent* rather than a root daemon, and land in the user's runtime
  # directory instead of /run/secrets.
  #
  # The private half of the age key lives at ~/.config/sops/age/keys.txt and is
  # never committed. It is this machine's trust anchor: another machine gets
  # its own key, and its public half is added to .sops.yaml.
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  sops = {
    defaultSopsFile = ../../secrets/fastmail.yaml;

    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    secrets = {
      # Read-only JMAP token, scoped to Email. It cannot send mail or create
      # Masked Email addresses; see modules/home/fastmail.nix.
      "token" = { };

      # Limited to DNS edits on glockyco.com. Deployment credentials remain
      # separate so a compromised project shell cannot rewrite mail or apex
      # records.
      "cloudflare-dns-token" = {
        sopsFile = ../../secrets/cloudflare.yaml;
        key = "token";
      };

      # Deployment token for Workers, D1, Queues, and Worker routes. Projects
      # opt in explicitly with `use cloudflare_workers` in their `.envrc`.
      "cloudflare-workers-token" = {
        sopsFile = ../../secrets/cloudflare-workers.yaml;
        key = "token";
      };
    };
  };

  # Keep the deployment credential out of the global shell. direnv loads this
  # helper automatically, but only projects that call it receive the token.
  home.file.".config/direnv/lib/use_cloudflare_workers.sh".text = ''
    use_cloudflare_workers() {
      local token_file=${config.sops.secrets."cloudflare-workers-token".path}

      if [[ ! -r "$token_file" ]]; then
        log_error "Cloudflare Workers token is unavailable: $token_file"
        return 1
      fi

      export CLOUDFLARE_API_TOKEN
      CLOUDFLARE_API_TOKEN="$(< "$token_file")"
    }
  '';
}
