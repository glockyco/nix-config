{ config, pkgs, ... }:

{
  services.postgresql = {
    enable = true;

    # Pinned rather than left to the module default, because a cluster's data
    # directory can only be opened by the major version that wrote it. An
    # implicit default moving under an existing cluster stops the server from
    # starting, so the upgrade has to be a deliberate edit here.
    package = pkgs.postgresql_17;

    # A launchd agent starts with no LANG, so initdb would otherwise pick SQL_ASCII, which stores
    # bytes unvalidated and reports an encoding clients cannot rely on. ICU ties collation to the
    # PostgreSQL build rather than to the host's libc.
    #
    # initdb only runs against an empty data directory, so this does not convert an existing cluster.
    initdbArgs = [
      "--encoding=UTF8"
      "--locale-provider=icu"
      "--icu-locale=en-US"
    ];

    # These lines land above nix-darwin's generated defaults, which ask for md5
    # over loopback. The module initialises the cluster with `initdb -U
    # postgres` and leaves that role without a password, and it implements
    # neither `initialScript` nor `ensureUsers` on darwin, so md5 would lock out
    # the only superuser on a fresh machine.
    authentication = ''
      host all all 127.0.0.1/32 trust
      host all all ::1/128      trust
    '';
  };

  # The server is a launchd *user* agent, so it cannot create its own data
  # directory below root-owned /var/lib and `initdb` fails before writing a log.
  system.activationScripts.extraActivation.text = ''
    /usr/bin/install -d -o ${config.system.primaryUser} -g staff -m 0700 \
      ${config.services.postgresql.dataDir}
  '';
}
