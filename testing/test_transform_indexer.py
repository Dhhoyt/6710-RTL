BLOCK_POWER: int = 4
BLOCK_SIZE: int = 1 << BLOCK_POWER

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
    angle = (pair << stage_inv) & ((1 << (BLOCK_POWER - 1)) - 1);
    return top, bottom, angle

for stage in range(BLOCK_POWER):
    print(f"stage: {stage}")
    for pair in range(BLOCK_SIZE // 2):
        top, bottom, angle = find_idx(stage, pair)
        print(f"({top}, {bottom}) with angle {angle}")


# expected:
# stage: 0
# (0, 4) with angle 0
# (1, 5) with angle 0
# (2, 6) with angle 0
# (3, 7) with angle 0
# stage: 1
# (0, 2) with angle 0
# (4, 6) with angle 2
# (1, 3) with angle 0
# (5, 7) with angle 2
# stage: 2
# (0, 1) with angle 0
# (4, 5) with angle 1
# (2, 3) with angle 2
# (6, 7) with angle 3
