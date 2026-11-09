import cmath
import math
import re
import subprocess
import sys
from pathlib import Path

from harness import GREEN, RED, RESET

PATTERN = re.compile(
    r"size=(\d+) block=(\d+) sample=(\d+) component=(\d+) value=(-?\d+)"
)
ROOT = Path(__file__).resolve().parent.parent
BASE_BLOCKS = 6
NOISE_BLOCKS = 128


def noise_sample(block: int, index: int, component: int) -> int:
    value = (0x12345678 ^ (block * 0x9E3779B9) ^
             (index * 0x85EBCA6B) ^ (component * 0xC2B2AE35)) & 0xFFFFFFFF
    value = ((value ^ (value >> 16)) * 0x7FEB352D) & 0xFFFFFFFF
    value = ((value ^ (value >> 15)) * 0x846CA68B) & 0xFFFFFFFF
    value ^= value >> 16
    return (value & 127) - 64


def input_sample(block: int, index: int, size: int) -> complex:
    if BASE_BLOCKS <= block < BASE_BLOCKS + size:
        phase = 2 * math.pi * (block - BASE_BLOCKS) * index / size
        return math.floor(32 * math.sin(phase) + 0.500000001)
    if block >= BASE_BLOCKS + size:
        noise_block = block - BASE_BLOCKS - size
        return complex(noise_sample(noise_block, index, 0), noise_sample(noise_block, index, 1))
    if block == 0:
        return 512 if index == 0 else 0
    if block == 1:
        return 256 if index == 1 else 0
    if block == 2:
        return 31
    if block == 3:
        return (48, 48j, -48, -48j)[index % 4]
    if block == 4:
        return complex((index * 29 + 7) % 97 - 48, (index * 17 + 3) % 83 - 41)
    return 0


def wrap(value: int) -> int:
    value &= 0xffff
    return value - 0x10000 if value >= 0x8000 else value


def fixed_fft(samples: list[complex]) -> list[tuple[int, int]]:
    size = len(samples)
    bits = size.bit_length() - 1
    reversed_indices = [int(f"{index:0{bits}b}"[::-1], 2) for index in range(size)]
    data = [(int(samples[index].real), int(samples[index].imag)) for index in reversed_indices]

    for stage in range(bits):
        half = 1 << stage
        for group in range(0, size, 2 * half):
            for offset in range(half):
                phase = 2 * math.pi * offset / (2 * half)
                real = math.floor(abs(math.cos(phase)) * 32767 + 0.5)
                imag = math.floor(abs(math.sin(phase)) * 32767 + 0.5)
                if math.cos(phase) < 0:
                    real = -real
                imag = -imag
                a_real, a_imag = data[group + offset]
                b_real, b_imag = data[group + offset + half]
                product_real = wrap(wrap((b_real * real) >> 15) - wrap((b_imag * imag) >> 15))
                product_imag = wrap(wrap((b_real * imag) >> 15) + wrap((b_imag * real) >> 15))
                data[group + offset] = (wrap(a_real + product_real), wrap(a_imag + product_imag))
                data[group + offset + half] = (wrap(a_real - product_real), wrap(a_imag - product_imag))
    return data


def main() -> None:
    size = int(sys.argv[1])
    binary = ROOT / "build" / f"fft_{size}.vvp"
    result = subprocess.run(["vvp", str(binary)], capture_output=True, text=True)
    if result.returncode:
        print(result.stdout + result.stderr)
        print(f"fft_{size}: {RED}FAIL (simulator exited with {result.returncode}){RESET}")
        sys.exit(1)

    lines = result.stdout.splitlines()
    observed = {}
    errors = []
    completed = False
    for line in lines:
        match = PATTERN.fullmatch(line)
        if match:
            output_size, block, sample, component, value = map(int, match.groups())
            key = (block, sample, component)
            if output_size != size or key in observed:
                errors.append(f"unexpected or duplicate output: {line}")
            observed[key] = value
        elif line == "fft test completed":
            completed = True
        elif "$finish called" not in line:
            errors.append(f"unexpected output: {line}")

    if not completed:
        errors.append("simulation did not complete")

    tolerance = size + 4 * int(math.log2(size))
    block_count = BASE_BLOCKS + size + NOISE_BLOCKS
    for block in range(block_count):
        inputs = [input_sample(block, n, size) for n in range(size)]
        fixed_expected = fixed_fft(inputs)
        for k in range(size):
            expected = sum(x * cmath.exp(-2j * math.pi * k * n / size)
                           for n, x in enumerate(inputs))
            for component, reference in enumerate((expected.real, expected.imag)):
                key = (block, k, component)
                actual = observed.pop(key, None)
                if actual is None or abs(actual - reference) > tolerance:
                    errors.append(f"{key}: expected {reference:.2f} +/- {tolerance}, got {actual}")
                elif actual != fixed_expected[k][component]:
                    errors.append(f"{key}: bit-exact expected {fixed_expected[k][component]}, got {actual}")

    if observed:
        errors.append(f"unexpected samples: {sorted(observed)}")
    for error in errors:
        print(f"FAIL: {error}")
    color = RED if errors else GREEN
    status = "FAIL" if errors else "PASS"
    print(f"fft_{size}: {color}{status} ({block_count} blocks, {size * block_count} complex outputs, {len(errors)} errors){RESET}")
    sys.exit(bool(errors))


if __name__ == "__main__":
    main()
