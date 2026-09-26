#!/usr/bin/env python3
import os
import sys

if sys.argv[1:] != ["integration", "status"]:
    sys.exit(2)
print(os.environ.get("STATUS", "omp: current (v8)"))
