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

    localparam integer BLOCK_SIZE = 1 << BLOCK_SIZE_POWER;
    localparam integer BIT_COUNT_WIDTH = (WIDTH > 1) ? $clog2(WIDTH + 1) : 1;

    reg [WIDTH-1:0] memory [0:2*BLOCK_SIZE-1];
    wire [BLOCK_SIZE_POWER:0] address;
    wire [BLOCK_SIZE_POWER-1:0] angle;
    wire [WIDTH-1:0] memory_data = memory[address];
    wire a_write_enable, b_write_enable, mem_write_enable;
    wire mark_data_read, send_output;
    wire [2:0] mem_input_source;

    reg signed [WIDTH-1:0] a_real, a_imag, b_real, b_imag;
    wire signed [WIDTH-1:0] sum_real, sum_imag, diff_real, diff_imag;
    reg [WIDTH-1:0] memory_write_data;

    reg [WIDTH-1:0] input_shift;
    reg [WIDTH-1:0] input_word;
    reg input_buffer_full;
    reg input_active;
    reg [BIT_COUNT_WIDTH-1:0] input_bit_count;
    reg [BLOCK_SIZE_POWER:0] input_word_count;

    reg [WIDTH-1:0] output_shift;
    reg [BIT_COUNT_WIDTH-1:0] output_bits_remaining;
    wire output_buffer_empty = output_bits_remaining <= 1;

    assign data_out = (output_bits_remaining != 0) ? output_shift[WIDTH-1] : 1'b0;

    controller #(
        .BLOCK_SIZE_POWER(BLOCK_SIZE_POWER)
    ) control (
        .clk(clk),
        .rst(rst),
        .begin_input(begin_input),
        .begin_output(begin_output),
        .input_buffer_full(input_buffer_full),
        .output_buffer_empty(output_buffer_empty),
        .mark_data_read(mark_data_read),
        .send_output(send_output),
        .a_write_enable(a_write_enable),
        .b_write_enable(b_write_enable),
        .address(address),
        .angle(angle),
        .mem_write_enable(mem_write_enable),
        .input_ready(input_ready),
        .output_ready(output_ready),
        .mem_input_source(mem_input_source)
    );

    butterfly_unit #(
        .INTEGER_WIDTH(INTEGER_WIDTH),
        .DECIMAL_WIDTH(DECIMAL_WIDTH),
        .BLOCK_POWER(BLOCK_SIZE_POWER),
        .WIDTH(WIDTH)
    ) butterfly (
        .a_real(a_real),
        .a_imag(a_imag),
        .b_real(b_real),
        .b_imag(b_imag),
        .angle(angle),
        .sum_real(sum_real),
        .sum_imag(sum_imag),
        .diff_real(diff_real),
        .diff_imag(diff_imag)
    );

    always_comb begin
        case (mem_input_source)
            3'b000: memory_write_data = input_word;
            3'b001: memory_write_data = sum_real;
            3'b010: memory_write_data = sum_imag;
            3'b011: memory_write_data = diff_real;
            3'b100: memory_write_data = diff_imag;
            default: memory_write_data = {WIDTH{1'bx}};
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            a_real <= 0;
            a_imag <= 0;
            b_real <= 0;
            b_imag <= 0;
        end else begin
            if (mem_write_enable)
                memory[address] <= memory_write_data;
            if (a_write_enable) begin
                if (address[0])
                    a_imag <= memory_data;
                else
                    a_real <= memory_data;
            end
            if (b_write_enable) begin
                if (address[0])
                    b_imag <= memory_data;
                else
                    b_real <= memory_data;
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            input_shift <= 0;
            input_word <= 0;
            input_buffer_full <= 0;
            input_active <= 0;
            input_bit_count <= 0;
            input_word_count <= 0;
        end else begin
            if (mark_data_read)
                input_buffer_full <= 0;

            if (begin_input && input_ready) begin
                input_active <= 1;
                input_bit_count <= 0;
                input_word_count <= 0;
            end else if (input_active) begin
                input_shift <= (input_shift << 1) | data_in;
                if (input_bit_count == WIDTH - 1) begin
                    input_word <= (input_shift << 1) | data_in;
                    input_buffer_full <= 1;
                    input_bit_count <= 0;
                    if (input_word_count == 2*BLOCK_SIZE - 1)
                        input_active <= 0;
                    else
                        input_word_count <= input_word_count + 1'b1;
                end else begin
                    input_bit_count <= input_bit_count + 1'b1;
                end
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            output_shift <= 0;
            output_bits_remaining <= 0;
        end else if (send_output) begin
            output_shift <= memory_data;
            output_bits_remaining <= WIDTH;
        end else if (output_bits_remaining != 0) begin
            output_shift <= output_shift << 1;
            output_bits_remaining <= output_bits_remaining - 1'b1;
        end
    end

endmodule
