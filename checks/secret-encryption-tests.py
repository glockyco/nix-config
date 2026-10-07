import base64
import importlib.util
import tempfile
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "secret_encryption", Path(__file__).with_name("secret-encryption-check.py")
)
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)


def fixture():
    key = base64.b64encode(bytes(32)).rstrip(b"=")
    return (
        b"age-encryption.org/v1\n-> X25519 "
        + key
        + b"\n"
        + key
        + b"\n--- "
        + key
        + b"\n"
        + bytes(32)
    )


class EncryptionTests(unittest.TestCase):
    def test_supported_encodings(self):
        raw = fixture()
        armor = (
            validator.ARMOR_BEGIN
            + b"\n"
            + b"\n".join(
                base64.b64encode(raw)[i : i + 64]
                for i in range(0, len(base64.b64encode(raw)), 64)
            )
            + b"\n"
            + validator.ARMOR_END
            + b"\n"
        )
        self.assertTrue(validator.valid_age(raw))
        self.assertTrue(validator.valid_age(armor))
        for invalid in [
            b"plaintext",
            raw[:22],
            raw[:-1],
            armor[:-12],
            raw.replace(b"--- ", b"bad "),
        ]:
            self.assertFalse(validator.valid_age(invalid))

    def test_inventory_and_attributes(self):
        with tempfile.TemporaryDirectory() as temp:
            source = Path(temp)
            data = source / ".chezmoidata"
            data.mkdir()
            (data / "credentials.toml").write_text(
                '[credentials]\ndirectory=".config/credentials"\nnames=["new-name"]\n'
            )
            parent = source / "dot_config/private_credentials"
            parent.mkdir(parents=True)
            path = parent / "encrypted_private_new-name.age"
            self.assertEqual(validator.inventory_errors(source), [path])
            path.write_bytes(fixture())
            self.assertEqual(validator.inventory_errors(source), [])
            path.rename(parent / "encrypted_new-name.age")
            self.assertEqual(len(validator.inventory_errors(source)), 2)
            (parent / "encrypted_new-name.age").rename(path)
            path.write_bytes(b"plaintext")
            self.assertEqual(validator.inventory_errors(source), [path])
            path.unlink()
            path.symlink_to(data / "credentials.toml")
            self.assertEqual(validator.inventory_errors(source), [path])


if __name__ == "__main__":
    unittest.main()
