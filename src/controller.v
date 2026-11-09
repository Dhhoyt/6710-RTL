module controller #(
    parameter integer BLOCK_SIZE_POWER = 8,
    parameter integer BLOCK_SIZE = 1 << BLOCK_SIZE_POWER
) (
    input  wire clk,
    input  wire rst,
    input  wire begin_input,
    input  wire begin_output,
    input  wire input_buffer_full,
    input  wire output_buffer_empty,
    output reg mark_data_read,
    output reg send_output,
    output reg a_write_enable,
    output reg b_write_enable,
    output reg [BLOCK_SIZE_POWER:0] address,
    output wire [BLOCK_SIZE_POWER-1:0] angle,
    output reg mem_write_enable,
    output reg input_ready,
    output reg output_ready,
    output reg [2:0] mem_input_source
);

    localparam integer INNER_COUNTER_WIDTH =
        (BLOCK_SIZE_POWER > 1) ? BLOCK_SIZE_POWER - 1 : 1;
    localparam integer STAGE_COUNTER_WIDTH =
        (BLOCK_SIZE_POWER > 1) ? $clog2(BLOCK_SIZE_POWER) : 1;

    localparam [3:0] IDLE = 4'b0000;
    localparam [3:0] INPUT = 4'b0001;
    localparam [3:0] OUTPUT = 4'b0010;
    localparam [3:0] TRANSFORM_LOAD_A_REAL = 4'b0011;
    localparam [3:0] TRANSFORM_LOAD_A_IMAG = 4'b0100;
    localparam [3:0] TRANSFORM_LOAD_B_REAL = 4'b0101;
    localparam [3:0] TRANSFORM_LOAD_B_IMAG = 4'b0110;
    localparam [3:0] TRANSFORM_STORE_A_REAL = 4'b0111;
    localparam [3:0] TRANSFORM_STORE_A_IMAG = 4'b1000;
    localparam [3:0] TRANSFORM_STORE_B_REAL = 4'b1001;
    localparam [3:0] TRANSFORM_STORE_B_IMAG = 4'b1010;
    localparam [3:0] DONE = 4'b1011;

    localparam [2:0] MEM_INPUT_DATA_IN = 3'b000;
    localparam [2:0] MEM_INPUT_SUM_REAL = 3'b001;
    localparam [2:0] MEM_INPUT_SUM_IMAG = 3'b010;
    localparam [2:0] MEM_INPUT_DIFF_REAL = 3'b011;
    localparam [2:0] MEM_INPUT_DIFF_IMAG = 3'b100;

    reg [3:0] state;
    reg [3:0] next_state;

    reg [INNER_COUNTER_WIDTH-1:0] inner_counter;
    reg [STAGE_COUNTER_WIDTH-1:0] stage_counter;
    reg [BLOCK_SIZE_POWER:0] input_output_counter;

    reg reset_input_output_counter;
    reg reset_transform_counters;
    reg increment_inner;
    reg increment_stage;
    reg increment_input_output_counter;

    wire [BLOCK_SIZE_POWER-1:0] idx1;
    wire [BLOCK_SIZE_POWER-1:0] idx2;
    wire [BLOCK_SIZE_POWER:0] output_memory_address;
    genvar output_bit;

    assign output_memory_address[0] = input_output_counter[0];
    generate
        for (output_bit = 0; output_bit < BLOCK_SIZE_POWER; output_bit = output_bit + 1) begin : output_address_bits
            assign output_memory_address[BLOCK_SIZE_POWER-output_bit] = input_output_counter[output_bit+1];
        end
    endgenerate

    transform_indexer #(
        .BLOCK_SIZE_POWER(BLOCK_SIZE_POWER),
        .BLOCK_SIZE(BLOCK_SIZE)
    ) transform_idx (
        .pair(inner_counter),
        .stage(stage_counter),
        .angle(angle),
        .top(idx1),
        .bot(idx2)
    );

    always @(posedge clk) begin
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
                input_output_counter <= input_output_counter + 1'b1;

            if (reset_transform_counters) begin
                inner_counter <= 0;
                stage_counter <= 0;
            end else begin
                if (increment_inner)
                    inner_counter <= inner_counter + 1'b1;
                if (increment_stage)
                    stage_counter <= stage_counter + 1'b1;
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
        reset_transform_counters = 0;
        mem_input_source = MEM_INPUT_DATA_IN;
        send_output = 0;
        mark_data_read = 0;

        case (state)
            IDLE: begin
                input_ready = 1;
                if (begin_input)
                    next_state = INPUT;
            end

            INPUT: begin
                reset_input_output_counter = 0;
                if (input_buffer_full) begin
                    increment_input_output_counter = 1;
                    mem_write_enable = 1;
                    address = input_output_counter;
                    mark_data_read = 1;
                    if (input_output_counter == (BLOCK_SIZE << 1) - 1)
                        next_state = TRANSFORM_LOAD_A_REAL;
                end
            end

            TRANSFORM_LOAD_A_REAL: begin
                a_write_enable = 1;
                address = {idx1, 1'b0};
                next_state = TRANSFORM_LOAD_A_IMAG;
            end

            TRANSFORM_LOAD_A_IMAG: begin
                a_write_enable = 1;
                address = {idx1, 1'b1};
                next_state = TRANSFORM_LOAD_B_REAL;
            end

            TRANSFORM_LOAD_B_REAL: begin
                b_write_enable = 1;
                address = {idx2, 1'b0};
                next_state = TRANSFORM_LOAD_B_IMAG;
            end

            TRANSFORM_LOAD_B_IMAG: begin
                b_write_enable = 1;
                address = {idx2, 1'b1};
                next_state = TRANSFORM_STORE_A_REAL;
            end

            TRANSFORM_STORE_A_REAL: begin
                mem_write_enable = 1;
                mem_input_source = MEM_INPUT_SUM_REAL;
                address = {idx1, 1'b0};
                next_state = TRANSFORM_STORE_A_IMAG;
            end

            TRANSFORM_STORE_A_IMAG: begin
                mem_write_enable = 1;
                mem_input_source = MEM_INPUT_SUM_IMAG;
                address = {idx1, 1'b1};
                next_state = TRANSFORM_STORE_B_REAL;
            end

            TRANSFORM_STORE_B_REAL: begin
                mem_write_enable = 1;
                mem_input_source = MEM_INPUT_DIFF_REAL;
                address = {idx2, 1'b0};
                next_state = TRANSFORM_STORE_B_IMAG;
            end

            TRANSFORM_STORE_B_IMAG: begin
                mem_write_enable = 1;
                mem_input_source = MEM_INPUT_DIFF_IMAG;
                address = {idx2, 1'b1};
                increment_inner = 1;

                if (inner_counter == (BLOCK_SIZE / 2) - 1) begin
                    if (stage_counter == BLOCK_SIZE_POWER - 1) begin
                        reset_transform_counters = 1;
                        next_state = DONE;
                    end else begin
                        increment_stage = 1;
                        next_state = TRANSFORM_LOAD_A_REAL;
                    end
                end else begin
                    next_state = TRANSFORM_LOAD_A_REAL;
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

            OUTPUT: begin
                reset_input_output_counter = 0;
                if (output_buffer_empty) begin
                    increment_input_output_counter = 1;
                    send_output = 1;
                    address = output_memory_address;

                    if (input_output_counter == (BLOCK_SIZE << 1) - 1)
                        next_state = IDLE;
                end
            end

            default: begin
                next_state = IDLE;
                reset_transform_counters = 1;
            end
        endcase
    end

endmodule
