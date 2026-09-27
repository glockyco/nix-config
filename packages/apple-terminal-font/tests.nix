{
  apple-terminal-font,
  lib,
  python3,
  runCommand,
}:

let
  command = lib.getExe apple-terminal-font;
in
runCommand "check-apple-terminal-font-command" { nativeBuildInputs = [ python3 ]; } ''
  cat > defaults-double <<'PY'
  #!/usr/bin/env python3
  import os
  import pathlib
  import sys

  action = sys.argv[1]
  assert sys.argv[2:] == ["com.apple.Terminal", "-"]
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
  export APPLE_TERMINAL_FONT_DEFAULTS="$PWD/defaults-double"
  export FONT_COMMAND='${command}'
  python3 - <<'PY'
  import os
  import pathlib
  import plistlib
  import subprocess

  from pathlib import Path

  state = Path("state.plist")
  calls = Path("calls")
  font = lambda name, size: plistlib.dumps({
      "$version": 100000,
      "$archiver": "NSKeyedArchiver",
      "$top": {"root": plistlib.UID(1)},
      "$objects": ["$null", {"$class": plistlib.UID(3), "NSName": plistlib.UID(2), "NSSize": size, "NSfFlags": 16}, name,
                   {"$classname": "NSFont", "$classes": ["NSFont", "NSObject"]}],
  }, fmt=plistlib.FMT_BINARY)
  prefs = {
      "Default Window Settings": "Default",
      "Startup Window Settings": "Startup",
      "Window Settings": {
          "Default": {"Font": font("Wanted", 16.5), "Other": "keep"},
          "Startup": {"Font": font("Wanted", 13)},
          "Unused": {"Font": font("Other", 9)},
      },
      "Unrelated": "keep",
  }
  state.write_bytes(plistlib.dumps(prefs))

  def run(*, fail=None):
      calls.write_text("")
      env = dict(os.environ)
      if fail:
          env["FAIL_DEFAULTS"] = fail
      else:
          env.pop("FAIL_DEFAULTS", None)
      result = subprocess.run([os.environ["FONT_COMMAND"], "Wanted"], capture_output=True, text=True, env=env)
      assert not result.stdout, result.stdout
      return result, calls.read_text().splitlines()

  before = state.stat().st_mtime_ns
  result, recorded = run()
  assert result.returncode == 0 and "current" in result.stderr, result
  assert recorded == ["export"], recorded
  assert state.stat().st_mtime_ns == before

  prefs["Window Settings"]["Startup"]["Font"] = font("Old", 13)
  state.write_bytes(plistlib.dumps(prefs))
  result, recorded = run()
  assert result.returncode == 0 and "Startup" in result.stderr, result
  assert recorded == ["export", "import"], recorded
  updated = plistlib.loads(state.read_bytes())
  assert updated["Unrelated"] == "keep"
  assert updated["Window Settings"]["Unused"] == prefs["Window Settings"]["Unused"]
  assert updated["Window Settings"]["Default"] == prefs["Window Settings"]["Default"]
  blob = plistlib.loads(updated["Window Settings"]["Startup"]["Font"])
  assert blob["$objects"][2] == "Wanted" and blob["$objects"][1]["NSSize"] == 13
  assert "current" in run()[0].stderr

  prefs.pop("Startup Window Settings")
  prefs["Default Window Settings"] = "Absent"
  state.write_bytes(plistlib.dumps(prefs))
  result, recorded = run()
  assert result.returncode == 0 and "current" in result.stderr, result
  assert recorded == ["export"], recorded
  assert plistlib.loads(state.read_bytes()) == prefs

  before = state.read_bytes()
  result, recorded = run(fail="export")
  assert result.returncode != 0 and "failed" in result.stderr, result
  assert recorded == ["export"] and state.read_bytes() == before

  prefs["Default Window Settings"] = "Default"
  prefs["Window Settings"]["Default"]["Font"] = font("Old", 16.5)
  state.write_bytes(plistlib.dumps(prefs))
  before = state.read_bytes()
  result, recorded = run(fail="import")
  assert result.returncode != 0 and "import" in result.stderr, result
  assert recorded == ["export", "import"] and state.read_bytes() == before
  PY
  touch "$out"
''
