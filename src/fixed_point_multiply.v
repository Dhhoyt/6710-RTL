module fixed_point_multiply #(
    parameter INTEGER_WIDTH = 8,
    parameter DECIMAL_WIDTH = 8
) (
    input signed  wire [INTEGER_WIDTH+DECIMAL_WIDTH-1:0] a,
    input signed  wire [INTEGER_WIDTH+DECIMAL_WIDTH-1:0] b,
    output signed wire [INTEGER_WIDTH+DECIMAL_WIDTH-1:0] result
);

    localparam W = INTEGER_WIDTH + DECIMAL_WIDTH;

    wire signed [W-1:0]   a, b;
    wire signed [2*W-1:0] full   = {{W{a[W-1]}}, a} * {{W{b[W-1]}}, b};                    
    wire signed [W-1:0]   result = full[DECIMAL_WIDTH +: W]; // drop F low bits and I high bits

endmodule