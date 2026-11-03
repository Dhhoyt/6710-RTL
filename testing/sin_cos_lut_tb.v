module sin_cos_lut_tb;
    localparam ANGLE_RESOLUTION_BITS = 8;
    localparam LUT_OUTPUT_BITS = 8;
    
    integer i; // 32-bit signed integer for loop iteration
    
    reg  [ANGLE_RESOLUTION_BITS-1:0] angle;
    wire signed [LUT_OUTPUT_BITS-1:0]       sin_val, cos_val;

    sin_cos_lut #(
        .ANGLE_RESOLUTION_BITS(ANGLE_RESOLUTION_BITS),
        .LUT_OUTPUT_BITS(LUT_OUTPUT_BITS)
    ) uut (
        .angle(angle),
        .sin_val(sin_val),
        .cos_val(cos_val)
    );

    initial begin
        for (i = 0; i < (1 << ANGLE_RESOLUTION_BITS); i = i + 1) begin
            angle = i[ANGLE_RESOLUTION_BITS-1:0];
            #1;
            $display("angle=%0d sin_val=%0d cos_val=%0d", angle, sin_val, cos_val);
        end
        $finish;
    end

endmodule