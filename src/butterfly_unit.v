`default_nettype none

module butterfly_unit #(
    parameter INTEGER_WIDTH = 8,
    parameter DECIMAL_WIDTH = 8,                             // fractional bits
    parameter BLOCK_POWER   = 8                              // 2^BLOCK_POWER-point FFT
)(
    input  wire signed [WIDTH-1:0]  a_real,
    input  wire signed [WIDTH-1:0]  a_imag,
    input  wire signed [WIDTH-1:0]  b_real,
    input  wire signed [WIDTH-1:0]  b_imag,
    input  wire        [BLOCK_POWER-1:0] angle,
    output wire signed [WIDTH-1:0]  sum_real,
    output wire signed [WIDTH-1:0]  sum_imag,
    output wire signed [WIDTH-1:0]  diff_real,
    output wire signed [WIDTH-1:0]  diff_imag
);

    localparam WIDTH = INTEGER_WIDTH + DECIMAL_WIDTH;

    wire signed [WIDTH-1:0] twiddle_real, twiddle_imag;

    sin_cos_lut #(
        .ANGLE_RESOLUTION_BITS(BLOCK_POWER),
        .LUT_OUTPUT_BITS      (WIDTH),
        .FRACTION_BITS        (DECIMAL_WIDTH)
    ) twiddle_lut (
        .angle  (angle),
        .sin_val(twiddle_imag),
        .cos_val(twiddle_real)
    );

    wire signed [WIDTH-1:0] q_first, q_outside, q_inside, q_final;

    fixed_point_multiply #(.INTEGER_WIDTH(INTEGER_WIDTH), .DECIMAL_WIDTH(DECIMAL_WIDTH))
        fp_mult_first   (.a(b_real), .b(twiddle_real), .result(q_first));
    fixed_point_multiply #(.INTEGER_WIDTH(INTEGER_WIDTH), .DECIMAL_WIDTH(DECIMAL_WIDTH))
        fp_mult_outside (.a(b_real), .b(twiddle_imag), .result(q_outside));
    fixed_point_multiply #(.INTEGER_WIDTH(INTEGER_WIDTH), .DECIMAL_WIDTH(DECIMAL_WIDTH))
        fp_mult_inside  (.a(b_imag), .b(twiddle_real), .result(q_inside));
    fixed_point_multiply #(.INTEGER_WIDTH(INTEGER_WIDTH), .DECIMAL_WIDTH(DECIMAL_WIDTH))
        fp_mult_final   (.a(b_imag), .b(twiddle_imag), .result(q_final));

    // q = b * W   (W = cos + j*sin)
    wire signed [WIDTH-1:0] q_real = q_first   - q_final;
    wire signed [WIDTH-1:0] q_imag = q_outside + q_inside;

    assign sum_real  = a_real + q_real;
    assign sum_imag  = a_imag + q_imag;
    assign diff_real = a_real - q_real;
    assign diff_imag = a_imag - q_imag;

endmodule

`default_nettype wire
