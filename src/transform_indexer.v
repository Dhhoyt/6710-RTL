module transform_indexer #(
    parameter integer BLOCK_SIZE_POWER = 8
) (
    reg [BLOCK_SIZE_POWER-2:0] inner_counter;
    reg [$clog2(BLOCK_SIZE_POWER)-1:0] stage_counter;

);

endmodule