import argparse
import json
import pathlib
import re
import subprocess
import sys
from collections import Counter
from importlib.resources import files
from typing import Sequence

import jsonschema
import yaml
from referencing import Registry, Resource
from referencing.jsonschema import DRAFT202012


PACKAGE_TYPE = "Microsoft.WinGet/Package"
SCRIPT_TYPE = "Microsoft.DSC.Transitional/WindowsPowerShellScript"
PRIMARY_FILES = {"configuration.winget", "apply-kbdneo.ps1", "apply-zen-policies.ps1"}
ADMIN_SCRIPTS = {"apply-kbdneo.ps1", "apply-zen-policies.ps1"}
FORBIDDEN_FEATURES = {
    "Microsoft.Windows/OptionalFeatureList",
    "PSDesiredStateConfiguration/WindowsFeature",
    "PSDesiredStateConfiguration/WindowsFeatureSet",
}
FIXED_ROLES = {
    "browser": ("Zen-Team.Zen-Browser", "exact", "machine"),
    "editor": ("ZedIndustries.Zed", "self-updating", "user"),
    "browser-relay": ("Brave.Brave", "self-updating", "user"),
    "communication-client": ("Ferdium.Ferdium", "self-updating", "user"),
}
SELF_UPDATING = {"editor", "browser-relay", "communication-client"}
PROFILE_OWNERS = {"browser-relay": "brave", "communication-client": "ferdium"}
DSC_URL = "https://raw.githubusercontent.com/PowerShell/DSC/main/"


class Finding(Exception):
    pass


class FindingParser(argparse.ArgumentParser):
    def error(self, message: str) -> None:
        raise Finding(f"arguments: {message}")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise Finding(message)


def mapping(value: object, label: str) -> dict:
    require(isinstance(value, dict), f"{label}: expected an object")
    return value


def load_json(path: pathlib.Path) -> dict:
    try:
        return mapping(json.loads(path.read_text(encoding="utf-8")), str(path))
    except json.JSONDecodeError as error:
        raise Finding(f"{path}: invalid JSON: {error.msg}") from error


def schema_registry(checkout: pathlib.Path) -> Registry:
    root = checkout / "schemas"
    require(root.is_dir(), f"{root}: DSC schemas are missing")
    registry = Registry()
    paths = sorted(root.rglob("*.json"))
    require(bool(paths), f"{root}: DSC schemas are empty")
    for path in paths:
        contents = load_json(path)
        identifier = contents.get("$id")
        if isinstance(identifier, str) and identifier.startswith(DSC_URL):
            registry = registry.with_resource(
                identifier,
                Resource.from_contents(contents, default_specification=DRAFT202012),
            )
    return registry


def validate_document(document: object, checkout: pathlib.Path) -> list[dict]:
    schema = json.loads(
        files(__package__).joinpath("winget-configuration.schema.json").read_text()
    )
    validator = jsonschema.Draft202012Validator(
        schema, registry=schema_registry(checkout)
    )
    errors = sorted(
        validator.iter_errors(document),
        key=lambda error: (list(map(str, error.path)), error.message),
    )
    if errors:
        error = errors[0]
        location = ".".join(str(part) for part in error.path)
        if (
            isinstance(document, dict)
            and len(error.path) >= 2
            and error.path[0] == "resources"
        ):
            resource = document["resources"][error.path[1]]
            location = (
                f"{resource.get('name', location)} ({location})"
                if isinstance(resource, dict)
                else location
            )
        raise Finding(f"configuration.winget {location or '$schema'}: {error.message}")
    resources = document["resources"]
    names = [resource["name"] for resource in resources]
    for name, count in Counter(names).items():
        require(count == 1, f"resource {name}: duplicate name")
    known = set(names)
    for resource in resources:
        for dependency in resource.get("dependsOn", []):
            require(
                dependency in known,
                f"resource {resource['name']}: unknown dependency {dependency}",
            )
    return resources


def validate_declaration(declaration: dict) -> dict[str, dict]:
    roles = declaration.get("roles")
    require(
        isinstance(roles, list)
        and len(roles) == 10
        and all(isinstance(role, str) and role for role in roles),
        "declaration roles: expected ten role names",
    )
    for role, count in Counter(roles).items():
        require(count == 1, f"declaration role {role}: duplicate")
    applications = declaration.get("applications")
    require(isinstance(applications, list), "declaration applications: expected a list")
    managed = declaration.get("managedApplications")
    require(
        isinstance(managed, list)
        and all(isinstance(identifier, str) for identifier in managed),
        "declaration managedApplications: expected identifiers",
    )
    by_role = {}
    for raw in applications:
        application = mapping(raw, "declaration application")
        role = application.get("role")
        require(
            isinstance(role, str) and role,
            f"application {application.get('name')}: missing role",
        )
        require(role in roles, f"application {role}: role is outside declaration roles")
        require(role not in by_role, f"application {role}: duplicate role")
        by_role[role] = application
        for key in ("name", "id", "source"):
            require(
                isinstance(application.get(key), str) and bool(application[key]),
                f"application {role}: missing {key}",
            )
        identifier = application["id"]
        require(
            identifier not in managed,
            f"application {role}: centrally managed identifier {identifier}",
        )
        require(
            application.get("scope") in {"user", "machine"},
            f"application {role}: invalid scope",
        )
        require(
            application["scope"] == ("machine" if role == "browser" else "user"),
            f"application {role}: unapproved machine scope",
        )
        policy = application.get("versionPolicy")
        require(
            policy in {"exact", "self-updating"},
            f"application {role}: invalid version policy",
        )
        require(
            policy == ("self-updating" if role in SELF_UPDATING else "exact"),
            f"application {role}: forbidden {policy} policy",
        )
        require(
            (
                isinstance(application.get("version"), str)
                and bool(application["version"])
            )
            if policy == "exact"
            else "version" not in application,
            f"application {role}: invalid version selector",
        )
        if role in FIXED_ROLES:
            expected_id, expected_policy, expected_scope = FIXED_ROLES[role]
            require(
                (identifier, policy, application["scope"], application["source"])
                == (expected_id, expected_policy, expected_scope, "winget"),
                f"application {role}: fixed identity or ownership differs ({identifier})",
            )
    missing = set(roles) - by_role.keys()
    if missing:
        raise Finding(
            f"application {sorted(missing)[0]}: declared role has no application"
        )
    for fixed_role in FIXED_ROLES:
        require(
            fixed_role in by_role, f"application {fixed_role}: required role is absent"
        )
    identifiers = [application["id"] for application in applications]
    for identifier, count in Counter(identifiers).items():
        require(count == 1, f"application {identifier}: duplicate identifier")
    return by_role


def validate_input_methods(declaration: dict) -> None:
    methods = mapping(declaration.get("inputMethods"), "declaration inputMethods")
    german = methods.get("german")
    default = methods.get("default")
    native_neo = methods.get("nativeNeo")
    require(
        isinstance(german, list)
        and len(german) >= 2
        and all(isinstance(tip, str) and tip for tip in german)
        and len(set(german)) == len(german),
        "declaration inputMethods german: expected distinct input tips",
    )
    require(
        isinstance(default, str) and isinstance(native_neo, str),
        "declaration inputMethods: expected default and nativeNeo tips",
    )
    require(
        native_neo in german,
        "declaration inputMethods: native Neo is not a German input method",
    )
    # Office derives character shortcuts from the first loaded layout, which is
    # the default input method. A native Neo default replaces Ctrl letter keys.
    require(
        default != native_neo,
        "declaration inputMethods: native Neo must not be the default input method",
    )
    require(
        german[0] == default,
        "declaration inputMethods: the default must be the first German input method",
    )


def validate_files(directory: pathlib.Path, declaration: dict) -> None:
    review = declaration.get("reviewFiles")
    require(
        isinstance(review, list)
        and len(review) == 16
        and all(
            isinstance(name, str) and name and pathlib.Path(name).name == name
            for name in review
        ),
        "declaration reviewFiles: expected sixteen file names",
    )
    require(len(set(review)) == len(review), "declaration reviewFiles: duplicate name")
    require(
        not (set(review) & PRIMARY_FILES),
        "declaration reviewFiles: contains a primary artifact",
    )
    expected = PRIMARY_FILES | set(review)
    actual = {entry.name for entry in directory.iterdir() if entry.is_file()}
    difference = expected ^ actual
    if difference:
        raise Finding(
            f"rendered Windows file {sorted(difference)[0]}: file set differs"
        )


def validate_applications(resources: list[dict], by_role: dict[str, dict]) -> None:
    seen = set()
    for resource in resources:
        name = resource["name"]
        metadata = resource.get("metadata", {})
        application = metadata.get("application")
        require(
            application is not None or resource["type"] != PACKAGE_TYPE,
            f"resource {name}: package has no application metadata",
        )
        if application is None:
            continue
        application = mapping(application, f"resource {name} application")
        roles = application.get("roles")
        require(
            isinstance(roles, list) and len(roles) == 1 and isinstance(roles[0], str),
            f"resource {name}: expected exactly one application role",
        )
        role = roles[0]
        require(role in by_role, f"resource {name}: undeclared role {role}")
        require(role not in seen, f"resource {name}: duplicate application role {role}")
        seen.add(role)
        declared = by_role[role]
        expected_name = "package " + role.replace("-", " ")
        require(
            name == expected_name,
            f"application {role}: expected resource {expected_name}, got {name}",
        )
        expected_metadata = {
            key: declared[key] for key in ("id", "source", "scope", "versionPolicy")
        }
        expected_metadata["roles"] = [role]
        if declared["versionPolicy"] == "exact":
            expected_metadata["version"] = declared["version"]
        require(
            application == expected_metadata,
            f"resource {name}: application metadata differs from declaration",
        )
        properties = resource["properties"]
        if declared["source"] == "winget":
            require(
                resource["type"] == PACKAGE_TYPE,
                f"resource {name}: expected WinGet package",
            )
            require(
                properties.get("id") == declared["id"]
                and properties.get("source") == "winget",
                f"resource {name}: package identifier or source differs",
            )
            if declared["versionPolicy"] == "exact":
                require(
                    properties.get("version") == declared["version"]
                    and properties.get("useLatest") is False,
                    f"resource {name}: exact version selector differs",
                )
            else:
                require(
                    "version" not in properties and properties.get("useLatest") is True,
                    f"resource {name}: self-updating selector differs",
                )
        else:
            require(
                resource["type"] == SCRIPT_TYPE,
                f"resource {name}: expected script installer",
            )
    for role in by_role.keys() - seen:
        raise Finding(
            f"application {role}: missing resource package {role.replace('-', ' ')}"
        )


def validate_boundaries(resources: list[dict]) -> None:
    for resource in resources:
        name = resource["name"]
        properties = resource["properties"]
        metadata = resource.get("metadata", {})
        security = metadata.get("winget", {}).get("securityContext")
        require(
            (security == "elevated")
            if name == "package browser"
            else security != "elevated",
            f"resource {name}: invalid elevation",
        )
        require(
            resource["type"] not in FORBIDDEN_FEATURES,
            f"resource {name}: Windows feature is forbidden",
        )
        key_path = properties.get("keyPath", "")
        if isinstance(key_path, str):
            require(
                not key_path.upper().startswith(
                    ("HKLM\\", "HKLM:\\", "HKEY_LOCAL_MACHINE\\")
                ),
                f"resource {name}: machine registry path {key_path}",
            )
            require(
                "cloudstore" not in key_path.casefold(),
                f"resource {name}: CloudStore path {key_path}",
            )
        for role, token in PROFILE_OWNERS.items():
            if name == "package " + role.replace("-", " "):
                continue
            values = (name, key_path, json.dumps(properties.get("valueData", "")))
            require(
                role.replace("-", " ") not in name.casefold()
                and not any(token in value.casefold() for value in values),
                f"resource {name}: {role} startup or profile ownership is forbidden",
            )


def parse_scripts(
    directory: pathlib.Path, resources: list[dict], declaration: dict
) -> None:
    scripts = {}
    for resource in resources:
        properties = resource["properties"]
        if resource["type"] == SCRIPT_TYPE:
            for key in ("testScript", "setScript"):
                require(
                    isinstance(properties.get(key), str),
                    f"resource {resource['name']} {key}: expected a script",
                )
        for key in ("testScript", "setScript"):
            if key in properties:
                require(
                    isinstance(properties[key], str),
                    f"resource {resource['name']} {key}: expected a script",
                )
                scripts[f"{resource['name']} {key}"] = properties[key]
    launchers = [
        name for name in declaration["reviewFiles"] if name.lower().endswith(".ps1")
    ]
    require(
        len(launchers) == 1, "declaration reviewFiles: expected one launcher script"
    )
    for name in (*sorted(ADMIN_SCRIPTS), *launchers):
        scripts[name] = (directory / name).read_text(encoding="utf-8")
    parser = files(__package__).joinpath("parse.ps1")
    result = subprocess.run(
        ["pwsh", "-NoProfile", "-NonInteractive", "-File", str(parser)],
        input=json.dumps(scripts),
        text=True,
        capture_output=True,
        check=False,
    )
    require(
        result.returncode == 0,
        f"parse.ps1: {result.stderr.strip() or 'PowerShell parser failed'}",
    )
    try:
        records = json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise Finding(f"parse.ps1: invalid parser output: {error.msg}") from error
    require(
        isinstance(records, list)
        and {record["name"] for record in records} == scripts.keys(),
        "parse.ps1: script results are incomplete",
    )
    for record in records:
        name = record["name"]
        errors = record["errors"]
        require(not errors, f"script {name}: {errors[0] if errors else ''}")
        for value in record["strings"]:
            require(
                "cloudstore" not in value.casefold(),
                f"script {name}: CloudStore string {value[:120]}",
            )
            if name in ADMIN_SCRIPTS:
                require(
                    not value.upper().startswith("HKCU:"),
                    f"script {name}: forbidden HKCU path {value[:120]}",
                )
                if value.upper().startswith("HKLM:"):
                    require(
                        name == "apply-kbdneo.ps1"
                        and value.upper().startswith(
                            "HKLM:\\SYSTEM\\CURRENTCONTROLSET\\CONTROL\\KEYBOARD LAYOUTS\\"
                        ),
                        f"script {name}: machine path outside ownership {value[:120]}",
                    )
                if re.match(r"^[a-zA-Z]:\\", value):
                    raise Finding(
                        f"script {name}: machine path outside ownership {value[:120]}"
                    )
        if name in ADMIN_SCRIPTS:
            for variable in record["variables"]:
                require(
                    variable.casefold()
                    not in {"env:appdata", "env:localappdata", "env:userprofile"},
                    f"script {name}: forbidden profile variable {variable}",
                )


def check(
    checkout: pathlib.Path, declaration_path: pathlib.Path, directory: pathlib.Path
) -> None:
    declaration = load_json(declaration_path)
    by_role = validate_declaration(declaration)
    validate_input_methods(declaration)
    validate_files(directory, declaration)
    document_path = directory / "configuration.winget"
    try:
        document = yaml.safe_load(document_path.read_text(encoding="utf-8"))
    except yaml.YAMLError as error:
        raise Finding(
            f"{document_path}: invalid YAML: {error.problem if hasattr(error, 'problem') else error}"
        ) from error
    resources = validate_document(document, checkout)
    validate_applications(resources, by_role)
    validate_boundaries(resources)
    parse_scripts(directory, resources, declaration)


def main(argv: Sequence[str] | None = None) -> int:
    parser = FindingParser(prog="windows-configuration-check")
    parser.add_argument("--schemas", type=pathlib.Path, required=True)
    parser.add_argument("--declaration", type=pathlib.Path, required=True)
    parser.add_argument("output_directory", type=pathlib.Path)
    try:
        args = parser.parse_args(sys.argv[1:] if argv is None else argv)
        check(args.schemas, args.declaration, args.output_directory)
    except (Finding, OSError, UnicodeError) as error:
        print(f"windows-configuration-check: {error}", file=sys.stderr)
        return 1
    return 0


def entry_point() -> None:
    sys.exit(main())
