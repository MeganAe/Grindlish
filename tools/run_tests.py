#!/usr/bin/env python3
"""Reproduce the integration checks using an installed Godot 4.3 binary.
Usage: GODOT=/path/to/godot python3 tools/run_tests.py
No dependency other than Python's standard library. No network access.
"""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[1]
GODOT = os.environ.get("GODOT") or shutil.which("godot") or shutil.which("godot4")
if not GODOT:
    sys.exit("Set GODOT to the Godot 4.3 executable.")
OUTPUT = ROOT / "docs/tests/lot2"
OUTPUT.mkdir(parents=True, exist_ok=True)
results = []
steps = [("import", ["--headless", "--editor", "--path", str(ROOT), "--import", "--quit"])]
for name in ("learning", "safety", "systems", "modes", "flow"):
    steps.append((name, ["--headless", "--path", str(ROOT), "--fixed-fps", "60", "--", f"--test={name}", "--nosave"]))
for name, args in steps:
    before = time.monotonic()
    try:
        proc = subprocess.run([GODOT, *args], capture_output=True, text=True, timeout=600)
        text = proc.stdout + proc.stderr
        status = proc.returncode
    except subprocess.TimeoutExpired as error:
        text = "TIMEOUT: " + str(error)
        status = 124
    (OUTPUT / (name + ".log")).write_text(text)
    errors = [line for line in text.splitlines() if line.startswith(("FAIL ", "SCRIPT ERROR:", "ERROR:"))]
    entry = {"test": name, "exit_code": status, "errors": errors, "seconds": round(time.monotonic() - before, 2)}
    results.append(entry)
    print(name, "OK" if status == 0 and not errors else "FAILED", entry["seconds"], flush=True)
(OUTPUT / "manifest.json").write_text(json.dumps(results, indent=2))
sys.exit(1 if any(r["exit_code"] or r["errors"] for r in results) else 0)
