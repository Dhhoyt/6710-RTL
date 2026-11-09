module butterfly_unit_tb;
  localparam integer INTEGER_WIDTH = 8;
  localparam integer DECIMAL_WIDTH = 8;
  localparam integer WIDTH = INTEGER_WIDTH + DECIMAL_WIDTH;
  localparam integer BLOCK_POWER = 4;

  reg signed [WIDTH-1:0] a_real, a_imag, b_real, b_imag;
  reg [BLOCK_POWER-1:0] angle;
  wire signed [WIDTH-1:0] sum_real, sum_imag, diff_real, diff_imag;

  integer angle_index;
  integer vector_index;

  butterfly_unit #(
      .INTEGER_WIDTH(INTEGER_WIDTH),
      .DECIMAL_WIDTH(DECIMAL_WIDTH),
      .BLOCK_POWER(BLOCK_POWER)
  ) uut (
      .a_real(a_real),
      .a_imag(a_imag),
      .b_real(b_real),
      .b_imag(b_imag),
      .angle(angle),
      .sum_real(sum_real),
      .sum_imag(sum_imag),
      .diff_real(diff_real),
      .diff_imag(diff_imag)
  );

  initial begin
    for (vector_index = 0; vector_index < 12500; vector_index = vector_index + 1) begin
      a_real = ((vector_index * 37 + 24) % (1 << WIDTH)) - (1 << (WIDTH - 1));
      a_imag = ((vector_index * 53 + 81) % (1 << WIDTH)) - (1 << (WIDTH - 1));
      b_real = ((vector_index * 97 + 146) % (1 << WIDTH)) - (1 << (WIDTH - 1));
      b_imag = ((vector_index * 29 + 211) % (1 << WIDTH)) - (1 << (WIDTH - 1));

      for (angle_index = 0; angle_index < (1 << BLOCK_POWER); angle_index = angle_index + 1) begin
        angle = angle_index;
        #1;
        $display(
            "angle=%0d a_real=%0d a_imag=%0d b_real=%0d b_imag=%0d sum_real=%0d sum_imag=%0d diff_real=%0d diff_imag=%0d",
            angle, a_real, a_imag, b_real, b_imag, sum_real, sum_imag, diff_real, diff_imag
        );
      end
    end
    $finish;
  end
endmodule
