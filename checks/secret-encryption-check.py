"""Validate age framing and source ownership without decrypting credentials."""

import argparse
import base64
import binascii
import re
import sys
import tomllib
from pathlib import Path
from typing import Sequence

ARMOR_BEGIN = b"-----BEGIN AGE ENCRYPTED FILE-----"
ARMOR_END = b"-----END AGE ENCRYPTED FILE-----"


def decode64(value: bytes) -> bytes:
    return base64.b64decode(value + b"=" * (-len(value) % 4), validate=True)


def valid_age(payload: bytes) -> bool:
    try:
        if payload.startswith(ARMOR_BEGIN):
            lines = payload.splitlines()
            if lines[0] != ARMOR_BEGIN or lines[-1] != ARMOR_END:
                return False
            if not lines[1:-1] or any(
                not line or len(line) > 64 for line in lines[1:-1]
            ):
                return False
            payload = base64.b64decode(b"".join(lines[1:-1]), validate=True)
        magic = b"age-encryption.org/v1\n"
        if not payload.startswith(magic):
            return False
        offset = len(magic)
        stanzas = 0
        while payload[offset:].startswith(b"-> "):
            end = payload.index(b"\n", offset)
            header = payload[offset:end]
            if not re.fullmatch(rb"-> [!-~]+(?: [!-~]+)*", header):
                return False
            offset = end + 1
            body = []
            while not payload[offset:].startswith((b"-> ", b"--- ")):
                end = payload.index(b"\n", offset)
                line = payload[offset:end]
                if len(line) > 64 or not re.fullmatch(rb"[A-Za-z0-9+/]*", line):
                    return False
                body.append(line)
                offset = end + 1
            if not body or len(body[-1]) >= 64:
                return False
            decode64(b"".join(body))
            stanzas += 1
        if not stanzas or not payload[offset:].startswith(b"--- "):
            return False
        end = payload.index(b"\n", offset)
        if len(decode64(payload[offset + 4 : end])) != 32:
            return False
        # A payload contains a 16-byte nonce and at least one 16-byte AEAD tag.
        # Authentication and recipient access remain separate decrypt gates.
        return len(payload[end + 1 :]) >= 32
    except (ValueError, binascii.Error):
        return False


def inventory_errors(source: Path) -> list[Path]:
    facts_path = source / ".chezmoidata/credentials.toml"
    try:
        facts = tomllib.loads(facts_path.read_text())["credentials"]
        names = facts["names"]
        if (
            not isinstance(names, list)
            or not names
            or any(
                not isinstance(name, str) or not re.fullmatch(r"[a-z0-9-]+", name)
                for name in names
            )
            or len(names) != len(set(names))
        ):
            return [facts_path]
        directory = facts["directory"]
        if directory != ".config/credentials":
            return [facts_path]
    except (OSError, ValueError, KeyError, TypeError):
        return [facts_path]
    parent = source / "dot_config/private_credentials"
    expected = {parent / f"encrypted_private_{name}.age" for name in names}
    actual = set(parent.iterdir()) if parent.is_dir() else set()
    actual.update(source.rglob("encrypted_*"))
    errors = list(actual - expected)
    for path in sorted(expected):
        try:
            if (
                not path.is_file()
                or path.is_symlink()
                or not valid_age(path.read_bytes())
            ):
                errors.append(path)
        except OSError:
            errors.append(path)
    return sorted(set(errors))


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    args = parser.parse_args(argv)
    errors = inventory_errors(args.source)
    for path in errors:
        print(f"invalid encrypted source: {path}", file=sys.stderr)
    return int(bool(errors))


if __name__ == "__main__":
    sys.exit(main())
