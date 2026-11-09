import math
import re

from harness import run_test

ANGLE_BITS = 8
OUT_BITS = 8
PAT = re.compile(r"angle=(\d+) sin_val=(-?\d+) cos_val=(-?\d+)")


def check_line(line: str) -> str | None:
    m = PAT.search(line)
    if not m:
        return None
    angle, sin_got, cos_got = map(int, m.groups())
    amp = 2 ** (OUT_BITS - 1) - 1
    a = 2 * math.pi * angle / (1 << ANGLE_BITS)
    sin_exp = math.floor(-math.sin(a) * amp + 0.5)
    cos_exp = math.floor(math.cos(a) * amp + 0.5)
    # allow 1 LSB: table is built from rounded quarter-wave samples
    if abs(sin_exp - sin_got) > 1 or abs(cos_exp - cos_got) > 1:
        return f"expected sin={sin_exp} cos={cos_exp}"


run_test("sin_cos_lut", check_line)
