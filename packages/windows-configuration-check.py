import copy
import json
import pathlib
import sys

import jsonschema
import yaml
from referencing import Registry, Resource
from referencing.jsonschema import DRAFT202012


PACKAGE_TYPE = "Microsoft.WinGet/Package"
FORBIDDEN_TYPES = {
    "Microsoft.Windows/OptionalFeatureList",
    "PSDesiredStateConfiguration/WindowsFeature",
    "PSDesiredStateConfiguration/WindowsFeatureSet",
}
EXPECTED_ROLES = {
    "browser",
    "editor",
    "git-client",
    "keyboard-layout",
    "launcher",
    "terminal",
    "terminal-font",
    "window-tool",
}
EXPECTED_FILES = {
    "apply-zen-policies.ps1",
    "power-toys-settings.json",
    "terminal-settings.json",
    "zed-settings.json",
    "zen-policies.json",
}


def schema_compatible_document(document: dict) -> dict:
    normalized = copy.deepcopy(document)
    resources = normalized.get("resources", [])
    resource_types = {
        resource.get("name"): resource.get("type") for resource in resources
    }
    if len(resource_types) != len(resources):
        raise ValueError("Windows resource names must be unique")

    for resource in resources:
        if "dependsOn" not in resource:
            continue
        dependencies = resource["dependsOn"]
        missing = [name for name in dependencies if name not in resource_types]
        if missing:
            raise ValueError(
                f"resource dependency does not exist: {', '.join(missing)}"
            )
        resource["dependsOn"] = [
            f"[resourceId('{resource_types[name]}', '{name}')]" for name in dependencies
        ]
    return normalized


def validate_policy(document: dict, managed_ids: set[str]) -> None:
    resources = document.get("resources", [])
    applications = [
        resource
        for resource in resources
        if resource.get("metadata", {}).get("application") is not None
    ]

    application_ids = [
        resource["metadata"]["application"].get("id") for resource in applications
    ]
    collisions = sorted(set(application_ids) & managed_ids)
    if collisions:
        raise ValueError(f"centrally managed package declared: {', '.join(collisions)}")

    roles = set()
    for resource in applications:
        name = resource.get("name", "")
        application = resource["metadata"]["application"]
        properties = resource.get("properties", {})
        if not name.startswith("package "):
            raise ValueError(f"package resource has no role name: {name}")
        declared_roles = application.get("roles")
        if not isinstance(declared_roles, list) or not declared_roles:
            raise ValueError(f"package has no declared roles: {application.get('id')}")
        roles.update(declared_roles)
        if not application.get("version"):
            raise ValueError(
                f"package has no explicit version: {application.get('id')}"
            )
        scope = application.get("scope")
        if scope not in {"user", "machine"}:
            raise ValueError(f"package has no explicit scope: {application.get('id')}")
        security_context = (
            resource.get("metadata", {}).get("winget", {}).get("securityContext")
        )
        if scope == "machine" and (
            name != "package browser" or security_context != "elevated"
        ):
            raise ValueError(
                f"unapproved machine package declared: {application.get('id')}"
            )
        if scope == "user" and security_context == "elevated":
            raise ValueError(
                f"user package requests elevation: {application.get('id')}"
            )
        if resource.get("type") == PACKAGE_TYPE:
            if properties.get("version") != application.get("version"):
                raise ValueError(
                    f"package version differs from its reviewed pin: {application.get('id')}"
                )
            if properties.get("useLatest") is not False:
                raise ValueError(
                    f"package permits an unpinned version: {application.get('id')}"
                )

    if roles != EXPECTED_ROLES:
        raise ValueError(f"application roles differ: {sorted(roles ^ EXPECTED_ROLES)}")

    for resource in resources:
        properties = resource.get("properties", {})
        metadata = resource.get("metadata", {})
        if str(properties.get("keyPath", "")).upper().startswith("HKLM\\"):
            raise ValueError(
                f"machine registry resource declared: {resource.get('name')}"
            )
        if resource.get("type") in FORBIDDEN_TYPES:
            raise ValueError(
                f"machine feature resource declared: {resource.get('name')}"
            )
        if metadata.get("winget", {}).get(
            "securityContext"
        ) == "elevated" and resource.get("name") not in {
            "package browser",
            "zen policies",
        }:
            raise ValueError(f"unapproved elevated resource: {resource.get('name')}")


def package_resource(role: str, package_id: str = "Example.Package") -> dict:
    return {
        "name": f"package {role.replace('-', ' ')}",
        "type": PACKAGE_TYPE,
        "properties": {
            "id": package_id,
            "source": "winget",
            "version": "1.0.0",
            "useLatest": False,
        },
        "metadata": {
            "application": {
                "id": package_id,
                "roles": [role],
                "source": "winget",
                "version": "1.0.0",
                "scope": "user",
            }
        },
    }


def run_rejection_tests() -> None:
    allowed = {
        "resources": [package_resource(role) for role in sorted(EXPECTED_ROLES)]
        + [
            {
                "name": "user-setting",
                "type": "Microsoft.Windows/Registry",
                "properties": {"keyPath": "HKCU\\Software\\Example"},
            }
        ]
    }
    validate_policy(allowed, {"Managed.Package"})

    cases = []

    unpinned = copy.deepcopy(allowed)
    unpinned["resources"][0]["metadata"]["application"]["version"] = ""
    cases.append(unpinned)

    mismatched = copy.deepcopy(allowed)
    mismatched["resources"][0]["properties"]["version"] = "2.0.0"
    cases.append(mismatched)

    latest = copy.deepcopy(allowed)
    latest["resources"][0]["properties"]["useLatest"] = True
    cases.append(latest)

    collision = copy.deepcopy(allowed)
    collision["resources"][0]["metadata"]["application"]["id"] = "Managed.Package"
    cases.append(collision)

    machine_registry = copy.deepcopy(allowed)
    machine_registry["resources"].append(
        {
            "name": "machine-setting",
            "type": "Microsoft.Windows/Registry",
            "properties": {"keyPath": "HKLM\\Software\\Example"},
        }
    )
    cases.append(machine_registry)

    elevated = copy.deepcopy(allowed)
    elevated["resources"].append(
        {
            "name": "elevated-setting",
            "type": "Microsoft.Windows/Registry",
            "properties": {"keyPath": "HKCU\\Software\\Example"},
            "metadata": {"winget": {"securityContext": "elevated"}},
        }
    )
    cases.append(elevated)

    feature = copy.deepcopy(allowed)
    feature["resources"].append(
        {
            "name": "feature",
            "type": "Microsoft.Windows/OptionalFeatureList",
            "properties": {},
        }
    )
    cases.append(feature)

    for case in cases:
        try:
            validate_policy(case, {"Managed.Package"})
        except ValueError:
            continue
        raise AssertionError("invalid Windows fixture passed policy validation")


def schema_registry(source_root: pathlib.Path) -> Registry:
    registry = Registry()
    for path in (source_root / "schemas").rglob("*.json"):
        contents = json.loads(path.read_text(encoding="utf-8"))
        resource = Resource.from_contents(contents, default_specification=DRAFT202012)
        relative = path.relative_to(source_root).as_posix()
        for revision in ("main", "45b10078ba49d9f9ec13b72c1040368eac9838e9"):
            uri = f"https://raw.githubusercontent.com/PowerShell/DSC/{revision}/{relative}"
            registry = registry.with_resource(uri, resource)
    return registry


def main() -> None:
    source_root, document_path, managed_path, package_root = map(
        pathlib.Path, sys.argv[1:]
    )
    schema_path = source_root / "schemas/2023/08/config/document.json"
    schema = json.loads(schema_path.read_text(encoding="utf-8"))
    document = yaml.safe_load(document_path.read_text(encoding="utf-8"))
    managed_ids = set(json.loads(managed_path.read_text(encoding="utf-8")))

    jsonschema.Draft202012Validator(
        schema, registry=schema_registry(source_root)
    ).validate(schema_compatible_document(document))
    validate_policy(document, managed_ids)

    elevated_resources = [
        resource.get("name")
        for resource in document.get("resources", [])
        if resource.get("metadata", {}).get("winget", {}).get("securityContext")
        == "elevated"
    ]
    if elevated_resources != ["package browser"]:
        raise ValueError("only the Zen package may be elevated in the WinGet document")

    missing = sorted(
        name for name in EXPECTED_FILES if not (package_root / name).is_file()
    )
    if missing:
        raise ValueError(f"rendered Windows files are missing: {', '.join(missing)}")

    power_toys = json.loads(
        (package_root / "power-toys-settings.json").read_text(encoding="utf-8")
    )
    enabled_modules = {
        name for name, enabled in power_toys.get("enabled", {}).items() if enabled
    }
    if enabled_modules != {"CmdPal", "GrabAndMove"}:
        raise ValueError("PowerToys must enable only Command Palette and Grab And Move")

    policy_script = (package_root / "apply-zen-policies.ps1").read_text(
        encoding="utf-8"
    )
    forbidden_profile_paths = ("HKCU", "LOCALAPPDATA", "USERPROFILE", "APPDATA")
    if any(path in policy_script.upper() for path in forbidden_profile_paths):
        raise ValueError("Zen policy script refers to an interactive-user profile path")
    if (
        "Zen Browser\\distribution\\policies.json" not in policy_script
        or "WindowsBuiltInRole]::Administrator" not in policy_script
    ):
        raise ValueError("Zen policy script does not enforce its privilege boundary")

    run_rejection_tests()


if __name__ == "__main__":
    main()
