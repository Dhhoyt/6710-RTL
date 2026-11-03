module fixed_point_multiply #(
    parameter integer INTEGER_WIDTH = 8,
    parameter integer DECIMAL_WIDTH = 8,
    parameter integer WIDTH = INTEGER_WIDTH + DECIMAL_WIDTH
) (
    input  wire signed [WIDTH-1:0] a,
    input  wire signed [WIDTH-1:0] b,
    output wire signed [WIDTH-1:0] result
);

  wire signed [2*WIDTH-1:0] full = {{WIDTH{a[WIDTH-1]}}, a} * {{WIDTH{b[WIDTH-1]}}, b};
  assign result = full[DECIMAL_WIDTH+:WIDTH];  // drop F low bits and I high bits

endmodule

