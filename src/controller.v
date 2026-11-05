module controller # (
    parameter integer BLOCK_SIZE_POWER = 8
) (
    input  wire clk,
    input  wire rst,
    input  wire begin_input,
    input  wire begin_output,
    output reg a_write_enable,
    output reg b_write_enable,
    output reg [7:0] address,
    output reg mem_write_enable,
    output reg input_ready,
    output reg output_ready
);

    localparam integer IDLE = 2'b00;
    localparam integer INPUT = 2'b01;
    localparam integer OUTPUT = 2'b10;
    localparam integer PROCESS = 2'b11;

    reg [1:0] main_state;
    reg [1:0] next_main_state;

    reg [BLOCK_SIZE_POWER-2:0] inner_counter;
    reg [$clog2(BLOCK_SIZE)-1:0] stage_counter;

    always @(posedge clk)
    begin
        if (rst)
            main_state <= IDLE;
        else
            main_state <= next_main_state;
    end

    always_comb begin
        a_write_enable = 0;
        b_write_enable = 0;
        mem_write_enable = 0;
        input_ready = 0;
        output_ready = 0;
        address = 0;

    end

endmodule

