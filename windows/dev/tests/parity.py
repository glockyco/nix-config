"""Compare real treefmt selection with the native plan in disposable trees."""

import json
from pathlib import Path
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[3]
FIXTURES = json.loads(
    (Path(__file__).with_name("formatting-fixtures.json")).read_text()
)


def run(*arguments, cwd=ROOT):
    return subprocess.run(
        arguments, cwd=cwd, check=True, capture_output=True, text=True
    ).stdout


def main():
    root = json.dumps(str(ROOT))
    expression = f"""
      let
        flake = builtins.getFlake {root};
        pkgs = import flake.inputs.nixpkgs {{ system = builtins.currentSystem; }};
      in (flake.inputs.treefmt-nix.lib.evalModule pkgs (builtins.toPath ({root} + "/treefmt.nix"))).config.settings
    """
    adapter = json.loads(run("nix", "eval", "--impure", "--json", "--expr", expression))
    run(
        "nix",
        "build",
        "--no-link",
        "--impure",
        "--expr",
        expression.replace(".config.settings", ".config.build.configFile"),
    )
    policy = json.loads((ROOT / "formatting.json").read_text())
    assert adapter["excludes"] == policy["excludes"], "Nix exclusion drift"
    assert set(adapter["formatter"]) == {item["name"] for item in policy["formatters"]}
    for item in policy["formatters"]:
        evaluated = adapter["formatter"][item["name"]]
        for field in ("includes", "priority"):
            assert evaluated[field] == item[field], (item["name"], field)
        options = list(evaluated["options"])
        for index, declared in enumerate(item["options"]):
            if declared == "@configuration@":
                assert (
                    json.loads(Path(options[index]).read_text())
                    == item["configuration"]
                )
                options[index] = declared
        assert options == item["options"], (item["name"], "options")
        if item["plugins"]:
            # The actual evaluated mdformat executable is built with the shared
            # plugin list by treefmt.nix, rather than an adapter-owned list.
            assert "mdformat" in evaluated["command"]
    with tempfile.TemporaryDirectory(prefix="formatter parity ") as directory:
        work = Path(directory)
        for name in FIXTURES["paths"]:
            target = work / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text("fixture\n")
        (work / "formatting.json").write_text(json.dumps(policy))
        run("git", "init", "--quiet", cwd=work)
        run("git", "add", "--all", cwd=work)
        native = json.loads(
            run(
                "pwsh",
                "-NoProfile",
                "-NonInteractive",
                "-File",
                str(ROOT / "windows/dev/format.ps1"),
                "-RepositoryRoot",
                str(work),
                "-Plan",
                "-IncludeNix",
            )
        )
        # The policy document itself is a tracked input too.
        native = [entry for entry in native if entry["path"] in FIXTURES["paths"]]
        record = work / "record.py"
        record.write_text(
            "#!/usr/bin/env python3\n"
            "import json, pathlib, sys, time\n"
            "name = pathlib.Path(sys.argv[0]).stem\n"
            "pathlib.Path('record-' + name + '-' + str(time.time_ns()) + '.log').write_text(json.dumps(sys.argv[1:]))\n"
        )
        config = ["excludes = " + json.dumps(adapter["excludes"])]
        for name, item in adapter["formatter"].items():
            executable = work / (name + ".py")
            executable.write_bytes(record.read_bytes())
            executable.chmod(0o755)
            config += [
                f"[formatter.{json.dumps(name)}]",
                "command = " + json.dumps(str(executable)),
                "includes = " + json.dumps(item["includes"]),
                "options = " + json.dumps(item["options"]),
                "priority = " + str(item["priority"]),
            ]
        configuration = work / "treefmt.toml"
        configuration.write_text("\n".join(config) + "\n")
        run(
            "nix",
            "shell",
            "--inputs-from",
            str(ROOT),
            "nixpkgs#treefmt",
            "-c",
            "treefmt",
            "--config-file",
            str(configuration),
            "--tree-root",
            str(work),
            "--no-cache",
            *FIXTURES["paths"],
            cwd=work,
        )
        actual = []
        ordered = {}
        for log in sorted(
            work.glob("record-*.log"), key=lambda path: path.name.rsplit("-", 1)[-1]
        ):
            name = log.name[7:].rsplit("-", 1)[0]
            arguments = json.loads(log.read_text())
            options = adapter["formatter"][name]["options"]
            assert arguments[: len(options)] == options, (name, arguments)
            for path in arguments[len(options) :]:
                relative = (
                    str(Path(path).relative_to(work))
                    if Path(path).is_absolute()
                    else path.removeprefix("./")
                )
                declared_options = next(
                    item["options"]
                    for item in policy["formatters"]
                    if item["name"] == name
                )
                actual.append((name, relative, tuple(declared_options)))
                ordered.setdefault(relative, []).append(name)
        expected = [
            (entry["name"], entry["path"], tuple(entry["options"])) for entry in native
        ]
        assert sorted(actual) == sorted(expected), (actual, expected)
        for path in FIXTURES["paths"]:
            assert ordered.get(path, []) == FIXTURES["selected"].get(path, []), (
                path,
                ordered.get(path),
            )
    print(
        "PASS actual Nix treefmt/native file selection, options, order and exclusions"
    )


if __name__ == "__main__":
    main()
