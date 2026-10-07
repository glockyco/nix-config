{
  karabiner-configuration,
  python3,
  runCommand,
}:
runCommand "check-karabiner-configuration-command" { nativeBuildInputs = [ python3 ]; } ''
  export FILTER_COMMAND='${karabiner-configuration}/bin/karabiner-configuration'
  python3 - <<'PY'
  import json
  import os
  from pathlib import Path
  import subprocess

  declaration = Path("managed.json")
  declaration.write_text('{"global": {"show_in_menu_bar": true}, "profiles": [{"name": "Neo2", "selected": true, "virtual_hid_keyboard": {"keyboard_type_v2": "iso"}, "complex_modifications": {"rules": [{"description": "managed", "manipulators": []}]}}]}')
  command = [os.environ["FILTER_COMMAND"], "--declaration", str(declaration)]
  def run(content):
      return subprocess.run(command, input=content, text=True, capture_output=True)
  absent = run("")
  assert absent.returncode == 0, absent.stderr
  current = json.loads(absent.stdout)
  current["ui_state"] = {"preserve": True}
  current["profiles"].insert(0, {"name": "Unmanaged", "selected": True, "ui_state": 42})
  merged = run(json.dumps(current))
  assert merged.returncode == 0, merged.stderr
  current = json.loads(merged.stdout)
  assert current["profiles"][0] == {"name": "Unmanaged", "selected": False, "ui_state": 42}
  assert [p["name"] for p in current["profiles"] if p["selected"]] == ["Neo2"]
  original = json.dumps(current, separators=(",", ":")) + "\n"
  repeated = run(original)
  assert repeated.returncode == 0 and repeated.stdout == original, repeated
  path = Path("settings.json")
  path.write_text("{broken")
  before = path.stat().st_mtime_ns
  failed = run(path.read_text())
  assert failed.returncode != 0 and not failed.stdout and failed.stderr
  assert path.read_text() == "{broken" and path.stat().st_mtime_ns == before
  declaration.unlink()
  failed = run(original)
  assert failed.returncode != 0 and not failed.stdout
  PY
  touch "$out"
''
