"""Checks sin_cos_lut_tb output (read from stdin) against a reference model."""
import math
import re
import sys

ANGLE_BITS = 8
OUT_BITS = 8


def expected(angle):
    amp = 2 ** (OUT_BITS - 1) - 1
    a = 2 * math.pi * angle / (1 << ANGLE_BITS)
    return math.floor(math.sin(a) * amp + 0.5), math.floor(math.cos(a) * amp + 0.5)


def main():
    pat = re.compile(r"angle=(\d+) sin_val=(-?\d+) cos_val=(-?\d+)")
    seen = {}
    for line in sys.stdin:
        m = pat.search(line)
        if m:
            seen[int(m[1])] = (int(m[2]), int(m[3]))

    errors = []
    for angle in range(1 << ANGLE_BITS):
        if angle not in seen:
            errors.append(f"angle {angle}: missing from output")
            continue
        exp, got = expected(angle), seen[angle]
        # allow 1 LSB: table is built from rounded quarter-wave samples
        if any(abs(e - g) > 1 for e, g in zip(exp, got)):
            errors.append(f"angle {angle}: expected {exp}, got {got}")

    for e in errors:
        print("FAIL:", e)
    print(f"sin_cos_lut: {'FAIL' if errors else 'PASS'} ({len(seen)} samples)")
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
