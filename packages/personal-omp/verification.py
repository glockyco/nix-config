import json
import os
import pathlib
import subprocess

state = pathlib.Path.home() / ".local/share/omp-dev"
generation = state / "generations/verified-generation"
checkout = generation / "checkout"
checkout.mkdir(parents=True)
(generation / "dev-profile").symlink_to(os.environ["OMP_BASH"])
launcher = generation / "omp"
launcher.write_bytes(pathlib.Path(os.environ["VERSION_PROBE"]).read_bytes())
launcher.chmod(0o755)
metadata = {
    "release": "v18.1.12",
    "upstream": "1" * 40,
    "patchBase": "a1b254047d12e143b7c6011536e918c6c35c5906",
    "patchTip": "62aa62869813e2834dc5887453f0f6c984953442",
    "commit": "2" * 40,
    "system": os.environ["OMP_SYSTEM"],
}
manifest = generation / "generation.json"
manifest.write_text(json.dumps(metadata))
current = state / "current"
current.symlink_to(generation.relative_to(state))
env = dict(os.environ, HERDR_BIN=os.environ["HERDR_PROBE"])


def run(**overrides):
    return subprocess.run(
        [os.environ["OMP_VERIFIER"]],
        env=dict(env, **overrides),
        text=True,
        capture_output=True,
    )


result = run()
assert result.returncode == 0, result
for value in (
    *metadata.values(),
    "18.1.12-patched",
    os.environ["OMP_PLUGIN"],
    f"plannotator {os.environ['OMP_PLANNOTATOR_VERSION']}",
    os.environ["OMP_PLANNOTATOR"],
    "omp: current (v8)",
):
    assert value in result.stdout, (value, result)
for overrides in (
    {"STATUS": "omp: outdated (v7)"},
    {"PROBE_VERSION": ""},
    {"PROBE_STATUS": "23"},
):
    result = run(**overrides)
    assert result.returncode != 0 and not result.stdout, result

manifest.write_text("invalid json")
result = run()
assert result.returncode != 0 and not result.stdout, result
manifest.write_text(json.dumps(metadata))
launcher.unlink()
result = run()
assert result.returncode == 1 and not result.stdout, result
assert str(launcher.resolve()) in result.stderr and "omp-dev-update" in result.stderr, (
    result
)
launcher.write_bytes(pathlib.Path(os.environ["VERSION_PROBE"]).read_bytes())
launcher.chmod(0o644)
result = run()
assert result.returncode == 1 and not result.stdout, result
assert str(launcher.resolve()) in result.stderr and "omp-dev-update" in result.stderr, (
    result
)
launcher.chmod(0o755)
current.unlink()
result = run()
assert result.returncode == 1 and not result.stdout, result
assert str(current) in result.stderr and "omp-dev-update" in result.stderr, result
