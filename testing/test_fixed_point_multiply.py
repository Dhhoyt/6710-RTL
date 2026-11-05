import re

from harness import run_test

DECIMAL_BITS = 8
INTEGER_BITS = 8
WIDTH = INTEGER_BITS + DECIMAL_BITS

PAT = re.compile(r"a=(-?\d+) b=(-?\d+) result=(-?\d+)")


def wrap_signed(x: int, bits: int) -> int:
    x &= (1 << bits) - 1
    return x - (1 << bits) if x >> (bits - 1) else x


def check_line(line: str) -> str | None:
    m = PAT.match(line)
    if not m:
        return None
    a, b, result = map(int, m.groups())
    expected = wrap_signed((a * b) >> DECIMAL_BITS, WIDTH)
    if result != expected:
        return f"a={a} b={b}: expected {expected}, got {result}"


run_test("fixed_point_multiply", check_line)
