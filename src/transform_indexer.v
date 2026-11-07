module transform_indexer #(
    parameter integer BLOCK_SIZE_POWER = 8,
    parameter integer BLOCK_SIZE = 1 << BLOCK_SIZE_POWER
) (
    input wire [BLOCK_SIZE_POWER-2:0] pair,
    input wire [$clog2(BLOCK_SIZE_POWER)-1:0] stage,
    output reg [BLOCK_SIZE_POWER-1:0] angle,
    output reg [BLOCK_SIZE_POWER-1:0] top,
    output reg [BLOCK_SIZE_POWER-1:0] bot
);

  assign stage_in = BLOCK_SIZE_POWER - stage - 1;
  assign top = ((pair >> stage_in) << (stage_in + 1)) | (pair & ((1 << stage_in) - 1));
  assign bot = top | (1 << stage);

endmodule

