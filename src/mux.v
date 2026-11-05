module mux2 #(
    parameter integer WIDTH = 16
) (
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    input  wire             sel,
    output wire [WIDTH-1:0] y
);

  assign y = sel ? b : a;

endmodule

module mux4 #(
    parameter integer WIDTH = 16
) (
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    input  wire [WIDTH-1:0] c,
    input  wire [WIDTH-1:0] d,
    input  wire [      1:0] sel,
    output wire [WIDTH-1:0] y
);

  assign y = (sel == 2'b00) ? a : (sel == 2'b01) ? b : (sel == 2'b10) ? c : d;

endmodule

