{
  lib,
  writeShellApplication,
}:

writeShellApplication {
  name = "power-settings";

  text = ''
    if [[ $# -ne 10 || $1 != -c || $2 != sleep || $4 != displaysleep || $6 != -b || $7 != sleep || $9 != displaysleep || ! $3 =~ ^[0-9]+$ || ! $5 =~ ^[0-9]+$ || ! $8 =~ ^[0-9]+$ || ! ''${10} =~ ^[0-9]+$ ]]; then
      printf '%s\n' 'power-settings: expected -c sleep N displaysleep N -b sleep N displaysleep N' >&2
      exit 64
    fi
    ac_sleep=$3
    ac_display=$5
    battery_sleep=$8
    battery_display=''${10}
    pmset_command="''${POWER_SETTINGS_PMSET:-/usr/bin/pmset}"

    if ! custom=$("$pmset_command" -g custom); then
      printf '%s\n' 'power-settings: could not read pmset -g custom' >&2
      exit 1
    fi

    source_name=
    ac_sleep_current=
    ac_display_current=
    battery_sleep_current=
    battery_display_current=
    while IFS= read -r line; do
      case "$line" in
        'AC Power:') source_name=ac ;;
        'Battery Power:') source_name=battery ;;
        *' Power:') source_name=other ;;
      esac
      if [[ $line =~ ^[[:space:]]*(sleep|displaysleep)[[:space:]]+([0-9]+)([[:space:]]|$) ]]; then
        key=''${BASH_REMATCH[1]}
        value=''${BASH_REMATCH[2]}
        case "$source_name:$key" in
          ac:sleep) ac_sleep_current=$value ;;
          ac:displaysleep) ac_display_current=$value ;;
          battery:sleep) battery_sleep_current=$value ;;
          battery:displaysleep) battery_display_current=$value ;;
        esac
      fi
    done <<< "$custom"

    if [[ -z $ac_sleep_current || -z $ac_display_current || -z $battery_sleep_current || -z $battery_display_current ]]; then
      printf '%s\n' 'power-settings: missing AC or battery sleep settings in pmset -g custom' >&2
      exit 1
    fi

    if [[ $ac_sleep_current == "$ac_sleep" && $ac_display_current == "$ac_display" ]]; then
      printf '%s\n' 'power-settings: AC current' >&2
    else
      "$pmset_command" -c sleep "$ac_sleep" displaysleep "$ac_display"
      printf 'power-settings: AC changed: sleep %s displaysleep %s\n' "$ac_sleep" "$ac_display" >&2
    fi

    if [[ $battery_sleep_current == "$battery_sleep" && $battery_display_current == "$battery_display" ]]; then
      printf '%s\n' 'power-settings: battery current' >&2
    else
      "$pmset_command" -b sleep "$battery_sleep" displaysleep "$battery_display"
      printf 'power-settings: battery changed: sleep %s displaysleep %s\n' "$battery_sleep" "$battery_display" >&2
    fi
  '';

  meta = {
    description = "Apply changed AC and battery sleep settings";
    mainProgram = "power-settings";
    platforms = lib.platforms.darwin;
  };
}
