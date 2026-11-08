module transform_indexer #(
    parameter integer BLOCK_SIZE_POWER = 8,
    parameter integer BLOCK_SIZE = 1 << BLOCK_SIZE_POWER
) (
    input wire [BLOCK_SIZE_POWER-2:0] pair,
    input wire [$clog2(BLOCK_SIZE_POWER)-1:0] stage,
    output wire [BLOCK_SIZE_POWER-1:0] angle,
    output wire [BLOCK_SIZE_POWER-1:0] top,
    output wire [BLOCK_SIZE_POWER-1:0] bot
);

  wire [BLOCK_SIZE_POWER-2:0] reversed_stage_pair_bits;
  wire [BLOCK_SIZE_POWER-1:0] stage_in;
  genvar bit_index;

  generate
    for (
        bit_index = 0; bit_index < BLOCK_SIZE_POWER - 1; bit_index = bit_index + 1
    ) begin : gen_reverse_stage_bits
      assign reversed_stage_pair_bits[bit_index] =
          (bit_index < stage) ? pair[stage - 1 - bit_index] : 1'b0;
    end
  endgenerate

  assign stage_in = BLOCK_SIZE_POWER - stage - 1;
  assign top = (reversed_stage_pair_bits << (BLOCK_SIZE_POWER - stage)) | (pair >> stage);
  assign bot = top | (1 << stage_in);
  assign angle = (pair << stage_in) & ((1 << (BLOCK_SIZE_POWER - 1)) - 1);

endmodule

