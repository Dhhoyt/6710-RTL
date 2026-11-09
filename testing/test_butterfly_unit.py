import math
import re

from harness import run_test

INTEGER_BITS = 8
DECIMAL_BITS = 8
WIDTH = INTEGER_BITS + DECIMAL_BITS
ANGLE_BITS = 4
AMPLITUDE = (1 << (WIDTH - 1)) - 1

PATTERN = re.compile(
    r"angle=(\d+) a_real=(-?\d+) a_imag=(-?\d+) b_real=(-?\d+) b_imag=(-?\d+) "
    r"sum_real=(-?\d+) sum_imag=(-?\d+) diff_real=(-?\d+) diff_imag=(-?\d+)"
)

QUARTER_TABLE = [
    math.floor(math.sin(2 * math.pi * index / (1 << ANGLE_BITS)) * AMPLITUDE + 0.5)
    for index in range((1 << (ANGLE_BITS - 2)) + 1)
]


def wrap_signed(value: int) -> int:
    value &= (1 << WIDTH) - 1
    return value - (1 << WIDTH) if value & (1 << (WIDTH - 1)) else value


def twiddle(angle: int) -> tuple[int, int]:
    quadrant = angle >> (ANGLE_BITS - 2)
    index = angle & ((1 << (ANGLE_BITS - 2)) - 1)
    direct = QUARTER_TABLE[index]
    mirror = QUARTER_TABLE[(1 << (ANGLE_BITS - 2)) - index]
    if quadrant == 0:
        return mirror, -direct
    if quadrant == 1:
        return -direct, -mirror
    if quadrant == 2:
        return -mirror, direct
    return direct, mirror


def multiply(a: int, b: int) -> int:
    return wrap_signed((a * b) >> (WIDTH - 1))


def check_line(line: str) -> str | None:
    match = PATTERN.fullmatch(line)
    if not match:
        return None

    angle, a_real, a_imag, b_real, b_imag, *actual = map(int, match.groups())
    twiddle_real, twiddle_imag = twiddle(angle)
    product_real = wrap_signed(
        multiply(b_real, twiddle_real) - multiply(b_imag, twiddle_imag)
    )
    product_imag = wrap_signed(
        multiply(b_real, twiddle_imag) + multiply(b_imag, twiddle_real)
    )
    expected = [
        wrap_signed(a_real + product_real),
        wrap_signed(a_imag + product_imag),
        wrap_signed(a_real - product_real),
        wrap_signed(a_imag - product_imag),
    ]
    if actual != expected:
        return f"expected {expected}, got {actual}"


run_test("butterfly_unit", check_line)
