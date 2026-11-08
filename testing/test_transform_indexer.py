import re

from harness import run_test


BLOCK_POWER: int = 8
PAT = re.compile(r"pair=(\d+) stage=(\d+) angle=(\d+) top=(\d+) bot=(\d+)")

def reverse_bits(value: int, width: int) -> int:
    """Reverse exactly ``width`` low-order bits of ``value``."""
    reversed_value = 0
    for _ in range(width):
        reversed_value = (reversed_value << 1) | (value & 1)
        value >>= 1
    return reversed_value

def find_idx(stage: int, pair: int) -> tuple[int, int, int]:
    stage_inv = BLOCK_POWER - stage - 1
    lower_pair_bits = reverse_bits(pair & ((1 << stage) - 1), stage)
    upper_pair_bits = pair >> stage
    top = (lower_pair_bits << (BLOCK_POWER - stage)) | upper_pair_bits
    bottom = top | (1 << stage_inv)
    angle = (pair << stage_inv) & ((1 << (BLOCK_POWER - 1)) - 1)
    return top, bottom, angle

def check_line(line: str) -> str | None:
    match = PAT.fullmatch(line)
    if match is None:
        return None

    pair, stage, angle, top, bottom = map(int, match.groups())
    expected_top, expected_bottom, expected_angle = find_idx(stage, pair)
    if (top, bottom, angle) != (expected_top, expected_bottom, expected_angle):
        return (
            f"pair={pair}, stage={stage}: expected "
            f"top={expected_top} bot={expected_bottom} angle={expected_angle}; "
            f"got top={top} bot={bottom} angle={angle}"
        )


run_test("transform_indexer", check_line)
