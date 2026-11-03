module sin_cos_lut_tb;
    localparam ANGLE_RESOLUTION_BITS = 8;
    localparam LUT_OUTPUT_BITS = 8;
    reg  [ANGLE_RESOLUTION_BITS-1:0] angle;
    wire [LUT_OUTPUT_BITS-1:0]       sin_val, cos_val;

    sin_cos_lut #(
        .ANGLE_RESOLUTION_BITS(ANGLE_RESOLUTION_BITS),
        .LUT_OUTPUT_BITS(LUT_OUTPUT_BITS)
    ) uut (
        .angle(angle),
        .sin_val(sin_val),
        .cos_val(cos_val)
    );

    initial begin
        for (angle = 0; angle < (1 << ANGLE_RESOLUTION_BITS); angle = angle + 1) begin
            #1;
            $display("angle=%0d sin_val=%0d cos_val=%0d", angle, sin_val, cos_val);
        end
        $finish;
    end

endmodule