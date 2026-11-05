module dff #(
    parameter integer WIDTH = 16
) (
    input  wire clk,
    input wire rst,
    input  wire [WIDTH-1:0] d,
    output reg  [WIDTH-1:0] q
);

    always @(posedge clk) begin
        if (rst) begin
            q <= 0;
        end else begin
            q <= d;
        end
    end

endmodule

