{ config, pkgs, ... }:
let
  home = config.users.users.${config.host.username}.home;
  log = "${home}/Library/Logs/personal-plugin-upgrade.log";
  plugins =
    (builtins.fromTOML (builtins.readFile ../../../../home/.chezmoidata/omp.toml)).omp.plugins;
  quote = pkgs.lib.escapeShellArg;
  forPlugins = render: pkgs.lib.concatMapStringsSep "\n    " render plugins;
  runner = pkgs.writeShellScript "personal-plugin-upgrade" ''
    set -eu
    export HOME=${quote home}
    export PATH="$HOME/.local/bin:${
      pkgs.lib.makeBinPath [
        pkgs.gh
        pkgs.git
      ]
    }:/usr/bin:/bin:/usr/sbin:/sbin"
    export GIT_TERMINAL_PROMPT=0
    export GIT_SSH_COMMAND="ssh -o BatchMode=yes"
    omp="$HOME/Library/Application Support/Tern/omp/bin/omp"
    echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') personal plugin update starting"
    finish() {
      result=$?
      echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') personal plugin update finished: $result"
    }
    trap finish EXIT

    run_command() {
      local status
      if ${pkgs.coreutils}/bin/timeout --kill-after=1s 300s "$@" < /dev/null; then
        return 0
      else
        status=$?
      fi
      if (( status == 124 || status == 137 )); then
        printf 'Command timed out: %s\n' "$*" >&2
      else
        printf 'Command failed (exit %s): %s\n' "$status" "$*" >&2
      fi
      return "$status"
    }

    check_git_auth() {
      local url="https://github.com/$1"
      if ! run_command ${pkgs.git}/bin/git ls-remote --exit-code "$url" HEAD; then
        printf 'Git cannot read %s: run gh auth login -h github.com --web\n' "$url"
      fi
    }

    declare -A registered=()
    parse_marketplaces() {
      local line header=0
      local row='^[[:blank:]]+([^[:blank:]]+)[[:blank:]]{2,}([^[:blank:]]+)[[:blank:]]*$'
      if [[ "$1" == $'No marketplaces configured\n\nAdd one with: omp plugin marketplace add <source>' ]]; then
        return 0
      fi
      while IFS= read -r line; do
        if [[ "$line" == 'Configured Marketplaces:' ]] && (( ! header )); then
          header=1
        elif [[ "$line" =~ ^[[:blank:]]*$ ]]; then
          continue
        elif (( header )) && [[ "$line" =~ $row ]]; then
          registered["''${BASH_REMATCH[1]}"]="''${BASH_REMATCH[2]}"
        else
          return 1
        fi
      done <<< "$1"
      (( header ))
    }

    check_source() {
      local marketplace="$1" source="$2" actual
      actual="''${registered[$marketplace]-}"
      if [[ -z "$actual" ]]; then
        printf 'Marketplace %s is not registered: run omp plugin marketplace add %s\n' "$marketplace" "$source"
      elif [[ "$actual" != "$source" ]]; then
        printf 'Marketplace %s is registered as %s, declared %s: run omp plugin marketplace remove %s && omp plugin marketplace add %s\n' \
          "$marketplace" "$actual" "$source" "$marketplace" "$source"
      fi
    }

    update_plugin() {
      local marketplace="$1" plugin="$2"
      if (( sources_known )) && [[ -z "''${registered[$marketplace]-}" ]]; then
        failed=1
      elif ! run_command "$omp" plugin marketplace update "$marketplace" ||
        ! run_command "$omp" plugin upgrade --scope user "$plugin"; then
        failed=1
      fi
    }

    ${forPlugins ({ source, ... }: "check_git_auth ${quote source}")}

    sources_known=0
    if listing=$(run_command "$omp" plugin marketplace list) && parse_marketplaces "$listing"; then
      sources_known=1
      ${forPlugins ({ marketplace, source, ... }: "check_source ${quote marketplace} ${quote source}")}
    else
      echo "Cannot read omp plugin marketplace list"
    fi

    failed=0
    ${forPlugins ({ marketplace, plugin, ... }: "update_plugin ${quote marketplace} ${quote plugin}")}
    exit "$failed"
  '';
in
{
  launchd.user.agents.personal-plugin-upgrade.serviceConfig = {
    ProgramArguments = [ "${runner}" ];
    RunAtLoad = true;
    StartInterval = 3600;
    ProcessType = "Background";
    LimitLoadToSessionType = "Aqua";
    StandardOutPath = log;
    StandardErrorPath = log;
  };
}
