{
  lib,
  python3,
  runCommand,
  symbolic-hotkeys,
}:

let
  command = lib.getExe symbolic-hotkeys;
in
runCommand "check-symbolic-hotkeys-command" { nativeBuildInputs = [ python3 ]; } ''
  cat > defaults-double <<'PY'
  #!/usr/bin/env python3
  import os
  import pathlib
  import sys

  action = sys.argv[1]
  assert sys.argv[2:] == ["com.apple.symbolichotkeys", "-"]
  with open("calls", "a") as log:
      log.write(action + "\n")
  if os.environ.get("FAIL_DEFAULTS") == action:
      print("fixture defaults " + action + " failed", file=sys.stderr)
      sys.exit(7)
  state = pathlib.Path("state.plist")
  if action == "export":
      sys.stdout.buffer.write(state.read_bytes())
  elif action == "import":
      state.write_bytes(sys.stdin.buffer.read())
  else:
      sys.exit(8)
  PY
  chmod +x defaults-double
  export SYMBOLIC_HOTKEYS_DEFAULTS="$PWD/defaults-double"
  export HOTKEYS_COMMAND='${command}'
  python3 - <<'PY'
  import os
  import plistlib
  import subprocess
  from pathlib import Path

  state = Path("state.plist")
  calls = Path("calls")
  prefs = {
      "Other": {"untouched": [1, 2]},
      "AppleSymbolicHotKeys": {
          "15": {"enabled": False, "value": "keep"},
          "16": {"enabled": True, "value": {"parameters": [1, 2, 3]}},
          "17": {"enabled": True},
      },
  }
  state.write_bytes(plistlib.dumps(prefs))

  def run(identifiers=("15",), fail=None):
      calls.write_text("")
      env = dict(os.environ)
      if fail:
          env["FAIL_DEFAULTS"] = fail
      else:
          env.pop("FAIL_DEFAULTS", None)
      result = subprocess.run([os.environ["HOTKEYS_COMMAND"], *identifiers], capture_output=True, text=True, env=env)
      assert not result.stdout, result.stdout
      return result, calls.read_text().splitlines()

  before = state.stat().st_mtime_ns
  result, recorded = run()
  assert result.returncode == 0 and "current" in result.stderr, result
  assert recorded == ["export"] and state.stat().st_mtime_ns == before

  result, recorded = run(("15", "16", "99"))
  assert result.returncode == 0 and "16, 99" in result.stderr, result
  assert recorded == ["export", "import"], recorded
  updated = plistlib.loads(state.read_bytes())
  assert updated["Other"] == prefs["Other"]
  assert updated["AppleSymbolicHotKeys"]["15"] == prefs["AppleSymbolicHotKeys"]["15"]
  assert updated["AppleSymbolicHotKeys"]["17"] == prefs["AppleSymbolicHotKeys"]["17"]
  assert updated["AppleSymbolicHotKeys"]["16"] == {"enabled": False, "value": {"parameters": [1, 2, 3]}}
  assert updated["AppleSymbolicHotKeys"]["99"] == {"enabled": False}
  result, recorded = run(("15", "16", "99"))
  assert result.returncode == 0 and "current" in result.stderr, result
  assert recorded == ["export"], recorded

  state.write_bytes(plistlib.dumps({"Other": prefs["Other"]}))
  result, recorded = run(("15",))
  assert result.returncode == 0 and recorded == ["export", "import"], result
  assert plistlib.loads(state.read_bytes()) == {"Other": prefs["Other"], "AppleSymbolicHotKeys": {"15": {"enabled": False}}}

  before = state.read_bytes()
  result, recorded = run(("15",), fail="export")
  assert result.returncode != 0 and "failed" in result.stderr, result
  assert recorded == ["export"] and state.read_bytes() == before

  state.write_bytes(plistlib.dumps(prefs))
  before = state.read_bytes()
  result, recorded = run(("16",), fail="import")
  assert result.returncode != 0 and "import" in result.stderr, result
  assert recorded == ["export", "import"] and state.read_bytes() == before
  PY
  touch "$out"
''
