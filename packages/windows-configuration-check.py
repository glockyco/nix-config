import copy
import hashlib
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
CATPPUCCIN_MOCHA = {
    "name": "Catppuccin Mocha",
    "cursorColor": "#F5E0DC",
    "selectionBackground": "#585B70",
    "background": "#1E1E2E",
    "foreground": "#CDD6F4",
    "black": "#45475A",
    "red": "#F38BA8",
    "green": "#A6E3A1",
    "yellow": "#F9E2AF",
    "blue": "#89B4FA",
    "purple": "#F5C2E7",
    "cyan": "#94E2D5",
    "white": "#BAC2DE",
    "brightBlack": "#585B70",
    "brightRed": "#F38BA8",
    "brightGreen": "#A6E3A1",
    "brightYellow": "#F9E2AF",
    "brightBlue": "#89B4FA",
    "brightPurple": "#F5C2E7",
    "brightCyan": "#94E2D5",
    "brightWhite": "#A6ADC8",
}
EXPECTED_POWERTOYS_MODULES = {
    "AdvancedPaste",
    "AltWindowCycle",
    "AlwaysOnTop",
    "Awake",
    "CmdNotFound",
    "CmdPal",
    "ColorPicker",
    "CropAndLock",
    "CursorWrap",
    "EnvironmentVariables",
    "FancyZones",
    "File Explorer Preview",
    "File Locksmith",
    "FindMyMouse",
    "GrabAndMove",
    "Hosts",
    "Image Resizer",
    "Keyboard Manager",
    "LightSwitch",
    "Measure Tool",
    "MouseHighlighter",
    "MouseJump",
    "MousePointerCrosshairs",
    "MouseWithoutBorders",
    "NewPlus",
    "Peek",
    "PowerDisplay",
    "PowerRename",
    "PowerToys Run",
    "QuickAccent",
    "RegistryPreview",
    "Shortcut Guide",
    "TextExtractor",
    "Workspaces",
    "ZoomIt",
}
FORBIDDEN_PROFILE_PATHS = (
    "HKCU:\\",
    "$ENV:LOCALAPPDATA",
    "$ENV:USERPROFILE",
    "$ENV:APPDATA",
)
EXPECTED_FILES = {
    "altsnap-package.json",
    "altsnap-settings.json",
    "apply-kbdneo.ps1",
    "apply-zen-policies.ps1",
    "fork-wslgit.json",
    "kbdneo.json",
    "power-toys-settings.json",
    "reneo-settings.json",
    "terminal-settings.json",
    "zed-catppuccin-theme.json",
    "zed-settings.json",
    "zen-catppuccin-logo.svg",
    "zen-catppuccin-userChrome.css",
    "zen-catppuccin-userContent.css",
    "zen-catppuccin.json",
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

    dark_appearance = next(
        resource
        for resource in document.get("resources", [])
        if resource.get("name") == "windows dark appearance"
    )
    dark_scripts = "\n".join(
        dark_appearance.get("properties", {}).get(name, "")
        for name in ("testScript", "setScript")
    )
    required_appearance_values = {
        "AppsUseLightTheme",
        "SystemUsesLightTheme",
        "EnableTransparency",
        "dark.theme",
        "img19.jpg",
        "SystemParametersInfo",
        "ImmersiveColorSet",
    }
    if any(value not in dark_scripts for value in required_appearance_values):
        raise ValueError("dark appearance resource is missing a declared setting")
    if "CloudStore" in document_path.read_text(encoding="utf-8"):
        raise ValueError(
            "the document must not rewrite Night Light CloudStore payloads"
        )

    reneo_startup = next(
        resource
        for resource in document.get("resources", [])
        if resource.get("name") == "keyboard layout startup"
    )
    expected_startup = (
        '"%LOCALAPPDATA%\\Microsoft\\WinGet\\Packages\\'
        'Rojetto.ReNeo.neo2_Microsoft.Winget.Source_8wekyb3d8bbwe\\ReNeo\\reneo.exe"'
    )
    if (
        reneo_startup.get("properties", {}).get("valueData", {}).get("ExpandString")
        != expected_startup
    ):
        raise ValueError("ReNeo startup must use the exact user-scope package path")
    native_neo = next(
        resource
        for resource in document.get("resources", [])
        if resource.get("name") == "native neo input method"
    )
    native_neo_scripts = "\n".join(
        native_neo.get("properties", {}).get(name, "")
        for name in ("testScript", "setScript")
    )
    if any(
        value not in native_neo_scripts
        for value in (
            "0407:b0000407",
            "Keyboard Layouts\\b0000407",
            "Get-WinUserLanguageList",
            "Set-WinUserLanguageList",
            "Set-WinDefaultInputMethodOverride",
        )
    ):
        raise ValueError("native Neo input selection is missing a required guard")
    alt_snap_startup = next(
        resource
        for resource in document.get("resources", [])
        if resource.get("name") == "window tool startup"
    )
    if (
        alt_snap_startup.get("properties", {}).get("valueData", {}).get("ExpandString")
        != '"%APPDATA%\\AltSnap\\AltSnap.exe"'
    ):
        raise ValueError("AltSnap startup must use the user-scope package path")

    json_resource_names = {
        "fork wslgit",
        "windows terminal settings",
        "zed settings",
        "reneo settings",
        "power toys settings",
    }
    for resource in document.get("resources", []):
        if resource.get("name") not in json_resource_names:
            continue
        set_script = resource.get("properties", {}).get("setScript", "")
        if "WriteAllText" not in set_script or "UTF8Encoding" not in set_script:
            raise ValueError("application JSON writers must emit UTF-8 without a BOM")

    font_resource = next(
        resource
        for resource in document.get("resources", [])
        if resource.get("name") == "package terminal font"
    )
    font_set_script = font_resource.get("properties", {}).get("setScript", "")
    if (
        "AddFontResourceEx" not in font_set_script
        or "SendMessageTimeout" not in font_set_script
    ):
        raise ValueError("font installation must activate faces in the current session")

    missing = sorted(
        name for name in EXPECTED_FILES if not (package_root / name).is_file()
    )
    if missing:
        raise ValueError(f"rendered Windows files are missing: {', '.join(missing)}")

    zen_theme = json.loads(
        (package_root / "zen-catppuccin.json").read_text(encoding="utf-8")
    )
    if {
        "commit": zen_theme.get("commit"),
        "flavor": zen_theme.get("flavor"),
        "accent": zen_theme.get("accent"),
        "preference": zen_theme.get("preference"),
        "files": {
            name: specification.get("sha256")
            for name, specification in zen_theme.get("files", {}).items()
        },
    } != {
        "commit": "c855685442c6040c4dda9c8d3ddc7b708de1cbaa",
        "flavor": "Mocha",
        "accent": "Mauve",
        "preference": {
            "name": "toolkit.legacyUserProfileCustomizations.stylesheets",
            "value": True,
        },
        "files": {
            "userChrome.css": "98ba97510bf2ecd8636686238242cb0f2e43552e2bb93c520818ed89da92189b",
            "userContent.css": "297a3c45e624792892482ab45552625b2765e6d44947e878fe5c5731eb7cd44a",
            "zen-logo.svg": "b41be8bf6c8659c532a0b1b984488696073adb31aec7a089211d4f4a7ecd9a83",
        },
    }:
        raise ValueError(
            "Zen Catppuccin theme must match the pinned Mocha Mauve sources"
        )
    zen_theme_resource = next(
        resource
        for resource in document.get("resources", [])
        if resource.get("name") == "zen catppuccin theme"
    )
    zen_theme_scripts = "\n".join(
        zen_theme_resource.get("properties", {}).get(name, "")
        for name in ("testScript", "setScript")
    )
    if any(
        value not in zen_theme_scripts
        for value in (
            "profiles.ini",
            "user.js",
            "toolkit.legacyUserProfileCustomizations.stylesheets",
            "Get-FileHash",
            "sha256",
            "Zen Browser\\zen.exe",
        )
    ):
        raise ValueError("Zen Catppuccin resource is missing a required profile guard")

    kbd_neo = json.loads((package_root / "kbdneo.json").read_text(encoding="utf-8"))
    if kbd_neo != {
        "version": "2022-10-04",
        "url": "https://dl.neo-layout.org/kbdneo64.zip",
        "archiveSha256": "66f8e7f18c95a9a4416acc3d3eb52afcdbc2a3278a7286136c574b3271add84c",
        "system32Sha256": "c5248c7b4024a2fdac956311a73a17428eab5fd54d59908a4a020501a49b775d",
        "sysWow64Sha256": "c10dfdb1ffd19f1a21b76f7288d3dde200ee19907bacd3acad8a70b19d887480",
        "layoutId": "b0000407",
        "layoutFile": "kbdneo2.dll",
        "layoutText": "Deutsch (Neo)",
    }:
        raise ValueError("kbdneo artifact must match the pinned 64-bit driver")
    kbd_neo_script = (package_root / "apply-kbdneo.ps1").read_text(encoding="utf-8")
    if any(
        value not in kbd_neo_script
        for value in (
            "WindowsBuiltInRole]::Administrator",
            "Is64BitProcess",
            "System32",
            "SysWOW64",
            "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Keyboard Layouts",
            "archiveSha256",
            "system32Sha256",
            "sysWow64Sha256",
            "kbdneo: desired",
        )
    ):
        raise ValueError("kbdneo administrator script is missing a required guard")
    if any(path in kbd_neo_script.upper() for path in FORBIDDEN_PROFILE_PATHS):
        raise ValueError("kbdneo script refers to an interactive-user profile path")

    wsl_git = json.loads(
        (package_root / "fork-wslgit.json").read_text(encoding="utf-8")
    )
    if wsl_git != {
        "version": "1.3.1",
        "url": "https://github.com/andy-5/wslgit/releases/download/v1.3.1/wslgit.zip",
        "archiveSha256": "88c0ad4c41c9fdcc522436fe7d0c808b192c2e47671816eb067a4d9740bc6807",
        "executableSha256": "f41ca507009b42871c0d55eaab24b41d821d5eb36e109e56e0cbba5020eded58",
        "forkIntegrationSha256": "cf0fde2c68c9bf891353dcc4f148a0fb3a1dd88b121d7d3e3b4c8577d71b9546",
    }:
        raise ValueError("Fork wslgit bridge must match the pinned release")
    fork_bridge = next(
        resource
        for resource in document.get("resources", [])
        if resource.get("name") == "fork wslgit"
    )
    fork_scripts = "\n".join(
        fork_bridge.get("properties", {}).get(name, "")
        for name in ("testScript", "setScript")
    )
    if any(
        value not in fork_scripts
        for value in ("GitInstancePath", "WSLGIT_DEFAULT_DIST", "NixOS", "Fork.RI")
    ):
        raise ValueError("Fork wslgit resource is missing a required bridge setting")

    alt_snap_package = json.loads(
        (package_root / "altsnap-package.json").read_text(encoding="utf-8")
    )
    if alt_snap_package != {
        "version": "1.68",
        "url": "https://github.com/RamonUnch/AltSnap/releases/download/1.68/AltSnap1.68bin_x64.zip",
        "archiveSha256": "7db3dad3746e7b23857db92fc05ee2d3e17eee1b28e237709a612366ba909c79",
        "executableSha256": "dba17fbfc2633aac31f5faedb992f4f24ddee3092bb4c803d2b8db83d58255b9",
        "hooksSha256": "fa2ff5c2f76267ab6a1d80e432649da023b94e2183fe2f8c27f254f1b0637ed7",
    }:
        raise ValueError("AltSnap must match the pinned portable release")
    alt_snap_resource = next(
        resource
        for resource in document.get("resources", [])
        if resource.get("name") == "package window tool"
    )
    alt_snap_scripts = "\n".join(
        alt_snap_resource.get("properties", {}).get(name, "")
        for name in ("testScript", "setScript")
    )
    if any(
        value not in alt_snap_scripts
        for value in ("archiveSha256", "executableSha256", "hooksSha256", "AltSnap.ini")
    ):
        raise ValueError("portable AltSnap resource is missing a checksum or setting")

    alt_snap = json.loads(
        (package_root / "altsnap-settings.json").read_text(encoding="utf-8")
    )
    if alt_snap != {
        "General": {
            "Aero": "1",
            "SmartAero": "1",
            "AutoSnap": "2",
            "AeroHoffset": "50",
            "AeroVoffset": "50",
        }
    }:
        raise ValueError("AltSnap must enable 50/50 edge snapping")

    power_toys = json.loads(
        (package_root / "power-toys-settings.json").read_text(encoding="utf-8")
    )
    module_flags = power_toys.get("enabled", {})
    if set(module_flags) != EXPECTED_POWERTOYS_MODULES:
        raise ValueError(
            "PowerToys module keys must match the installed version's schema"
        )
    enabled_modules = {name for name, enabled in module_flags.items() if enabled}
    if enabled_modules != {"CmdPal"}:
        raise ValueError("PowerToys must enable only Command Palette")
    if {
        "startup": power_toys.get("startup"),
        "run_elevated": power_toys.get("run_elevated"),
        "enable_quick_access": power_toys.get("enable_quick_access"),
    } != {"startup": True, "run_elevated": False, "enable_quick_access": False}:
        raise ValueError("PowerToys must start unelevated without Quick Access")

    reneo = json.loads(
        (package_root / "reneo-settings.json").read_text(encoding="utf-8")
    )
    if reneo != {"standaloneLayout": "Neo", "standaloneMode": False}:
        raise ValueError("ReNeo must extend the native Neo2 layout")
    reneo_resource = next(
        resource
        for resource in document.get("resources", [])
        if resource.get("name") == "reneo settings"
    )
    if "native neo input method" not in reneo_resource.get("dependsOn", []):
        raise ValueError("ReNeo settings must wait for native Neo input selection")

    terminal = json.loads(
        (package_root / "terminal-settings.json").read_text(encoding="utf-8")
    )
    zed = json.loads((package_root / "zed-settings.json").read_text(encoding="utf-8"))
    if (
        terminal.get("settings", {})
        .get("profiles", {})
        .get("defaults", {})
        .get("font", {})
        .get("face")
        != "JetBrainsMonoNL NF"
    ):
        raise ValueError("Windows Terminal must use the font's embedded family name")
    if {
        zed.get("buffer_font_family"),
        zed.get("terminal", {}).get("font_family"),
    } != {"JetBrainsMonoNL NF"}:
        raise ValueError("Zed must use the font's embedded Windows family name")
    if terminal.get("scheme") != CATPPUCCIN_MOCHA or (
        terminal.get("settings", {})
        .get("profiles", {})
        .get("defaults", {})
        .get("colorScheme")
        != "Catppuccin Mocha"
    ):
        raise ValueError(
            "Windows Terminal must use the official Catppuccin Mocha scheme"
        )
    if zed.get("theme") != {
        "dark": "Catppuccin Mocha",
        "light": "Catppuccin Mocha",
    }:
        raise ValueError("Zed must select Catppuccin Mocha")
    if zed.get("languages", {}).get("Nix", {}).get("language_servers") != [
        "nixd",
        "!nil",
    ] or zed.get("lsp", {}).get("nixd", {}).get("binary") != {
        "path": "nixd",
        "ignore_system_version": False,
    }:
        raise ValueError("Zed must use nixd from the WSL environment")
    zed_theme_digest = hashlib.sha256(
        (package_root / "zed-catppuccin-theme.json").read_bytes()
    ).hexdigest()
    if (
        zed_theme_digest
        != "2dccb9fb3ff888e646407b4f84d400304553e0d9a9688ac75d0f9fcd3f8bdf6a"
    ):
        raise ValueError("rendered Zed theme does not match the pinned upstream source")

    policy_script = (package_root / "apply-zen-policies.ps1").read_text(
        encoding="utf-8"
    )
    if any(path in policy_script.upper() for path in FORBIDDEN_PROFILE_PATHS):
        raise ValueError("Zen policy script refers to an interactive-user profile path")
    if (
        "Zen Browser\\distribution\\policies.json" not in policy_script
        or "WindowsBuiltInRole]::Administrator" not in policy_script
    ):
        raise ValueError("Zen policy script does not enforce its privilege boundary")

    run_rejection_tests()


if __name__ == "__main__":
    main()
