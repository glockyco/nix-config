#!/usr/bin/env python3
import json
import os
import shutil
import sys

print(
    json.dumps(
        {
            "args": sys.argv[1:],
            "cwd": os.getcwd(),
            "omp": shutil.which("omp"),
            "launcher": sys.argv[0],
            "nixd": shutil.which("nixd"),
            "plannotator": shutil.which("plannotator"),
        }
    )
)
sys.exit(int(os.environ.get("PROBE_STATUS", "0")))
