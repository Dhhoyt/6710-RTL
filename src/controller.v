module controller # (
    parameter integer BLOCK_SIZE_POWER = 8,
    parameter integer BLOCK_SIZE = 1 << BLOCK_SIZE_POWER
) (
    input  wire clk,
    input  wire rst,
    input  wire begin_input, // Signal to start receiving input data
    input  wire begin_output, // Signal to start sending output data
    input  wire input_buffer_full, // If the 16 bit input buffer is and ready to be placed into memory
    input  wire output_buffer_empty, // If the 16 bit output buffer is empty and ready to receive data
    output reg send_output,
    output reg a_write_enable,
    output reg b_write_enable,
    output reg [BLOCK_SIZE_POWER:0] address, // Stores twice the block size to store both real and imaginary parts
    output reg mem_write_enable,
    output reg input_ready,
    output reg output_ready,
    output reg [2:0] mem_input_source
);

    localparam integer IDLE = 4'b0000; // Waiting for data for next calculation
    localparam integer INPUT = 4'b0001; // In the process of receiving input data
    localparam integer OUTPUT = 4'b0010; // In the process of sending output data
    localparam integer TRANSFORM_LOAD_A_REAL = 4'b0011;
    localparam integer TRANSFORM_LOAD_A_IMAG = 4'b0100;
    localparam integer TRANSFORM_LOAD_B_REAL = 4'b0101;
    localparam integer TRANSFORM_LOAD_B_IMAG = 4'b0110;
    localparam integer TRANSFORM_STORE_A_REAL = 4'b0111;
    localparam integer TRANSFORM_STORE_A_IMAG = 4'b1000;
    localparam integer TRANSFORM_STORE_B_REAL = 4'b1001;
    localparam integer TRANSFORM_STORE_B_IMAG = 4'b1010;
    localparam integer DONE = 4'b1011; // Finished processing and ready for output

    localparam integer MEM_INPUT_DATA_IN = 3'b000;
    localparam integer MEM_INPUT_SUM_REAL = 3'b001;
    localparam integer MEM_INPUT_SUM_IMAG = 3'b010;
    localparam integer MEM_INPUT_DIFF_REAL = 3'b011;
    localparam integer MEM_INPUT_DIFF_IMAG = 3'b100;

    reg [3:0] state;
    reg [3:0] next_state;

    reg [BLOCK_SIZE_POWER-2:0] inner_counter; // Counts which butterfly we're on within a stage
    reg [$clog2(BLOCK_SIZE)-1:0] stage_counter; // Counts which stage of the FFT we're in

    reg [BLOCK_SIZE_POWER:0] input_output_counter; // Used to keep track of the current input/output element within a block
    reg reset_input_output_counter;
    reg reset_transform_counters;

    reg increment_inner;
    reg increment_stage;
    reg increment_input_output_counter;

    always @(posedge clk)
    begin
        if (rst) begin
            state <= IDLE;
            inner_counter <= 0;
            stage_counter <= 0;
            input_output_counter <= 0;
        end else begin
            state <= next_state;
            if (reset_input_output_counter)
                input_output_counter <= 0;
            else if (increment_input_output_counter)
                input_output_counter <= input_output_counter + 1;
            if (reset_transform_counters) begin
                inner_counter <= 0;
                stage_counter <= 0;
            end else begin
                if (increment_inner)
                    inner_counter <= inner_counter + 1;
                if (increment_stage)
                    stage_counter <= stage_counter + 1;
            end
        end
    end

    always_comb begin
        a_write_enable = 0;
        b_write_enable = 0;
        mem_write_enable = 0;
        input_ready = 0;
        output_ready = 0;
        address = 0;
        next_state = state;
        increment_inner = 0;
        increment_stage = 0;
        increment_input_output_counter = 0;
        reset_input_output_counter = 1;
        reset_transform_counters = 1;
        mem_input_source = MEM_INPUT_DATA_IN;
        case (state)
            IDLE: begin
                input_ready = 1;
                if (begin_input && !input_buffer_full)
                    next_state = INPUT;
            end
            INPUT: begin
                reset_input_output_counter = 0;
                if (input_buffer_full) begin
                    increment_input_output_counter = 1;
                    mem_write_enable = 1;
                    address = input_output_counter;
                    if (input_output_counter == (BLOCK_SIZE << 1)-1)
                        next_state = TRANSFORM_LOAD_A_REAL;
                end
            end 
            OUTPUT: begin
                reset_input_output_counter = 0;
                if (output_buffer_empty) begin
                    increment_input_output_counter = 1;
                    send_output = 1;
                    ///TODO: output indexer
                    if (input_output_counter == (BLOCK_SIZE << 1)-1)
                        next_state = IDLE;
                end
            end
            DONE: begin
                input_ready = 1;
                output_ready = 1;
                if (begin_input)
                    next_state = INPUT;
                else if (begin_output)
                    next_state = OUTPUT;
            end
            TRANSFORM_LOAD_A_REAL: begin
                
            end
        endcase
    end

endmodule

