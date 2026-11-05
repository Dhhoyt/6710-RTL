module fft #(
    parameter integer DECIMAL_WIDTH = 8,
    parameter integer INTEGER_WIDTH = 8,
    parameter integer WIDTH = DECIMAL_WIDTH + INTEGER_WIDTH,
    parameter integer BLOCK_SIZE_POWER = 8
) (
    input  wire clk,
    input  wire rst,
    input  wire data_in,
    input  wire begin_input,
    input  wire begin_output,
    output wire data_out,
    output wire input_ready,
    output wire output_ready
);



endmodule

