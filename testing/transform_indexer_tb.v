module transform_indexer_tb;
  localparam integer BLOCK_SIZE_POWER = 8;

  reg [BLOCK_SIZE_POWER-2:0] pair;
  reg [$clog2(BLOCK_SIZE_POWER)-1:0] stage;
  wire [BLOCK_SIZE_POWER-1:0] angle, top, bot;
  integer pair_i, stage_i;

  transform_indexer #(
      .BLOCK_SIZE_POWER(BLOCK_SIZE_POWER)
  ) uut (
      .pair (pair),
      .stage(stage),
      .angle(angle),
      .top  (top),
      .bot  (bot)
  );

  initial begin
    for (stage_i = 0; stage_i < BLOCK_SIZE_POWER; stage_i = stage_i + 1) begin
      for (pair_i = 0; pair_i < (1 << (BLOCK_SIZE_POWER - 1)); pair_i = pair_i + 1) begin
        stage = stage_i;
        pair  = pair_i;
        #1;
        $display("pair=%0d stage=%0d angle=%0d top=%0d bot=%0d", pair, stage, angle, top, bot);
      end
    end
    $finish;
  end
endmodule
