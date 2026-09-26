import json
import os
import pathlib
import subprocess

wrapper = os.environ["OMP_WRAPPER"]
plugin = os.environ["OMP_PLUGIN"]
home = pathlib.Path.home()
state = home / ".local/share/omp-dev"
generation = state / "generations/selected generation"
generation.mkdir(parents=True)
launcher = generation / "omp"
launcher.write_bytes(pathlib.Path(os.environ["GENERATION_PROBE"]).read_bytes())
launcher.chmod(0o755)
current = state / "current"
current.symlink_to(generation.relative_to(state))
retained = state / "generations/retained"
retained.mkdir()
(retained / "omp").write_text("retained source launcher\n")
(state / "previous").symlink_to(retained.relative_to(state))
agent = home / ".omp/agent"
agent.mkdir(parents=True)
(agent / "settings.json").write_text('{"defaultModel": "preserve-me"}\n')
official = home / ".local/lib/oh-my-pi/omp"
official.parent.mkdir(parents=True)
official.write_bytes(launcher.read_bytes())
official.chmod(0o755)
work = home / "project with spaces"
work.mkdir()
plugin_args = ["--extension", plugin, "--plugin-dir", f"{plugin}/lsp"]
conflicting = home / "caller bin"
conflicting.mkdir()
(conflicting / "plannotator").write_bytes(
    pathlib.Path(os.environ["CONFLICTING_PLANNOTATOR"]).read_bytes()
)
(conflicting / "plannotator").chmod(0o755)
caller_path = (
    str(conflicting)
    + ":"
    + str(pathlib.Path(wrapper).parent)
    + ":"
    + os.environ["PATH"]
)
env = dict(os.environ, PATH=caller_path)


def snapshot():
    return {
        str(path.relative_to(home)): (
            path.lstat().st_mode,
            os.readlink(path)
            if path.is_symlink()
            else path.read_bytes()
            if path.is_file()
            else None,
        )
        for path in home.rglob("*")
    }


def run(args, status=0):
    before = snapshot()
    result = subprocess.run(
        [wrapper, *args],
        cwd=work,
        env=dict(env, PROBE_STATUS=str(status)),
        text=True,
        capture_output=True,
        timeout=15,
    )
    assert snapshot() == before, "wrapper changed source or application state"
    return result


for args, status in (
    ([], 0),
    (["--print", "update", "argument with spaces", ""], 23),
    (["acp"], 0),
):
    result = run(args, status)
    assert result.returncode == status, result
    assert json.loads(result.stdout) == {
        "args": plugin_args + args,
        "cwd": str(work.resolve()),
        "omp": wrapper,
        "launcher": str(launcher.resolve()),
        "nixd": os.environ["OMP_NIXD"],
        "plannotator": os.environ["OMP_PLANNOTATOR"],
    }, result

result = run(["update", "--check", "argument with spaces"])
assert result.returncode == 1 and not result.stdout, result
assert "omp-dev-update" in result.stderr, result

launcher.chmod(0o644)
result = run([])
assert result.returncode == 1 and not result.stdout, result
assert str(launcher.resolve()) in result.stderr and "omp-dev-update" in result.stderr, (
    result
)
launcher.chmod(0o755)
launcher.unlink()
result = run([])
assert result.returncode == 1 and not result.stdout, result
assert str(launcher.resolve()) in result.stderr and "omp-dev-update" in result.stderr, (
    result
)
launcher.write_bytes(pathlib.Path(os.environ["GENERATION_PROBE"]).read_bytes())
launcher.chmod(0o755)
current.unlink()
for dangling in (False, True):
    if dangling:
        current.symlink_to("generations/absent")
    result = run([])
    assert result.returncode == 1 and not result.stdout, result
    assert str(current) in result.stderr and "omp-dev-update" in result.stderr, result
    result = run(["update"])
    assert result.returncode == 1 and not result.stdout, result
    assert "omp-dev-update" in result.stderr and str(current) not in result.stderr, (
        result
    )
