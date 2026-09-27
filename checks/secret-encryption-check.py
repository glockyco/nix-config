import sys
from pathlib import Path

import yaml


class UniqueSafeLoader(yaml.SafeLoader):
    def construct_mapping(self, node, deep=False):
        self.flatten_mapping(node)
        result = {}
        for key_node, value_node in node.value:
            key = self.construct_object(key_node, deep=deep)
            if key in result:
                raise ValueError("duplicate YAML key")
            result[key] = self.construct_object(value_node, deep=deep)
        return result


def data_paths(file):
    try:
        with file.open(encoding="utf-8") as stream:
            document = yaml.load(stream, Loader=UniqueSafeLoader)
    except (OSError, UnicodeError, yaml.YAMLError, ValueError, TypeError):
        return [("<root>", "invalid YAML")]

    if not isinstance(document, dict):
        return [("<root>", "expected a YAML mapping")]

    errors = []
    active = set()

    def walk(value, path):
        if isinstance(value, (dict, list)):
            identity = id(value)
            if identity in active:
                errors.append((path, "cyclic YAML alias"))
                return
            active.add(identity)
            if isinstance(value, dict):
                for key, child in value.items():
                    if isinstance(key, str) and key.isidentifier():
                        child_path = f"{path}.{key}" if path else key
                    else:
                        child_path = f"{path}[{key!r}]"
                    walk(child, child_path)
            else:
                for index, child in enumerate(value):
                    walk(child, f"{path}[{index}]")
            active.remove(identity)
        elif not isinstance(value, str) or not value.startswith("ENC["):
            errors.append((path, "plaintext data scalar"))

    for key, value in document.items():
        if key == "sops" and isinstance(value, dict):
            continue
        walk(value, str(key))
    return errors


def main(secrets, fixtures):
    cases = {
        "encrypted.yaml": [],
        "plaintext-map.yaml": [("service.credentials.token", "plaintext data scalar")],
        "plaintext-list.yaml": [
            ("providers[1].api_key", "plaintext data scalar"),
            ("providers[1].sops.note", "plaintext data scalar"),
            ("labels[1]", "plaintext data scalar"),
        ],
    }
    for name, expected in cases.items():
        actual = data_paths(fixtures / name)
        if actual != expected:
            print(f"fixture {name}: expected {expected}, got {actual}", file=sys.stderr)
            return 1

    files = sorted(secrets.glob("*.yaml"))
    if not files:
        print("secrets/: no YAML secret files", file=sys.stderr)
        return 1
    failures = 0
    for file in files:
        for path, reason in data_paths(file):
            print(f"secrets/{file.name}: {path}: {reason}", file=sys.stderr)
            failures += 1
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main(Path(sys.argv[1]), Path(sys.argv[2])))
