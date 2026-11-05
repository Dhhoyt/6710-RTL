module transform_indexer #(
    parameter integer BLOCK_SIZE_POWER = 8,
    parameter integer BLOCK_SIZE = 1 << BLOCK_SIZE_POWER
) (
    input wire [BLOCK_SIZE_POWER-2:0] inner_counter,
    input wire [$clog2(BLOCK_SIZE_POWER)-1:0] stage_counter,
    output reg [BLOCK_SIZE_POWER-1:0] angle,
    output reg [BLOCK_SIZE_POWER-1:0] idx1,
    output reg [BLOCK_SIZE_POWER-1:0] idx2
);



endmodule

