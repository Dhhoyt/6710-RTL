module fixed_point_multiply_tb;

    localparam INTEGER_BITS = 8;
    localparam DECIMAL_BITS = 8;

    localparam WIDTH = INTEGER_BITS + DECIMAL_BITS;

    reg signed [WIDTH-1:0] a, b;
    wire signed [WIDTH-1:0] result;

    fixed_point_multiply #(
        .INTEGER_WIDTH(INTEGER_BITS),
        .DECIMAL_WIDTH(DECIMAL_BITS)
    ) uut (
        .a(a),
        .b(b),
        .result(result)
    );

    integer a_int, b_int;
    
    initial begin
        // Check all decimal values for a and b with integer part of 0
        for (a_int = -128; a_int < 128; a_int = a_int + 1) begin
            for (b_int = -128; b_int < 128; b_int = b_int + 1) begin
                a = a_int;
                b = b_int;
                #1;
                $display("a=%0d b=%0d result=%0d", a, b, result);
            end
        end

        // Check all integer values for a and b with decimal part of 0
        for (a_int = -128; a_int < 128; a_int = a_int + 1) begin
            for (b_int = -128; b_int < 128; b_int = b_int + 1) begin
                a = a_int << DECIMAL_BITS;
                b = b_int << DECIMAL_BITS;
                #1;
                $display("a=%0d b=%0d result=%0d", a, b, result);
            end
        end
        // Test essentially random values
        for (a_int = -32768; a_int < 32768; a_int = a_int + 274) begin // 743 is arbitrary to cover random ranges
            for (b_int = -32768; b_int < 32768; b_int = b_int + 233) begin // Again, arbitrary step to cover range
                a = a_int;
                b = b_int;
                #1;
                $display("a=%0d b=%0d result=%0d", a, b, result);
            end
        end
        $finish;
    end

endmodule