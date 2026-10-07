{
  zed-configuration,
  python3,
  runCommand,
}:
runCommand "check-zed-configuration-command" { nativeBuildInputs = [ python3 ]; } ''
  export FILTER_COMMAND='${zed-configuration}/bin/zed-configuration'
  python3 - <<'PY'
  import json
  import os
  from pathlib import Path
  import subprocess

  declaration = Path("managed.json")
  declaration.write_text('{"vim_mode":true}')
  command = [os.environ["FILTER_COMMAND"], "--declaration", str(declaration)]
  def run(content):
      return subprocess.run(command, input=content, text=True, capture_output=True)
  absent = run("")
  assert absent.returncode == 0, absent.stderr
  current = json.loads(absent.stdout)
  current["ui_state"] = {"preserve": True}
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
