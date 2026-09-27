{ lib, pkgs, ... }:

let
  airBatchCheck = pkgs.air-batch-check;
  airHost = {
    HostName = "macbook-air";
    User = "joaichberger";
  };
in
{
  home.packages = lib.mkOrder 400 [ airBatchCheck ];

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      # The old MacBook Air is a temporary tailnet peer. Its account differs
      # from the local account, which holds the enrolled Secure Enclave key.
      air = airHost;

      # Unattended commands exit with their remote process. Keep stdin for rsync.
      air-batch = airHost // {
        BatchMode = "yes";
        RequestTTY = "no";
        ControlMaster = "no";
        ControlPath = "none";
        ControlPersist = "no";
        ConnectTimeout = 8;
      };
    };
  };
}
