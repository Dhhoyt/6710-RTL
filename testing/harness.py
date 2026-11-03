"""Tiny test harness: run a compiled testbench and check every output line.

Usage from a test script:
    from harness import run_test
    run_test("my_test", check_line)

check_line(line) is called for each line the testbench prints. It returns
None if the line is fine (or irrelevant), or an error string if it is wrong.
The vvp file is expected at build/<name>.vvp (built by the Makefile).
"""
import os
import subprocess
import sys
from collections.abc import Callable

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def run_test(name: str, check_line: Callable[[str], str | None], vvp: str = "vvp"):
    path = os.path.join(ROOT, "build", f"{name}.vvp")
    proc = subprocess.run([vvp, path], capture_output=True, text=True)
    if proc.returncode != 0:
        print(proc.stdout + proc.stderr)
        print(f"{name}: FAIL (simulator exited with {proc.returncode})")
        sys.exit(1)

    lines = proc.stdout.splitlines()
    errors: list[str] = []
    for n, line in enumerate(lines, 1):
        err: str | None = check_line(line)
        if err:
            errors.append(f"line {n} ({line!r}): {err}")

    for e in errors:
        print("FAIL:", e)
    print(f"{name}: {'FAIL' if errors else 'PASS'} ({len(lines)} lines, {len(errors)} errors)")
    sys.exit(1 if errors else 0)
