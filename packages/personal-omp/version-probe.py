#!/usr/bin/env python3
import os
import sys

plugin = os.environ["OMP_PLUGIN"]
if sys.argv[1:] != [
    "--extension",
    plugin,
    "--plugin-dir",
    f"{plugin}/lsp",
    "--version",
]:
    sys.exit(2)
print(os.environ.get("PROBE_VERSION", "18.1.12-patched"))
sys.exit(int(os.environ.get("PROBE_STATUS", "0")))
