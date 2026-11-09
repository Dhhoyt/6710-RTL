module fft_tb;
    parameter integer POWER = 3;
    localparam integer SIZE = 1 << POWER;
    localparam integer WIDTH = 16;
    localparam integer BASE_BLOCKS = 6;
    localparam integer NOISE_BLOCKS = 128;
    localparam integer BLOCKS = BASE_BLOCKS + SIZE + NOISE_BLOCKS;

    reg clk = 0;
    reg rst = 1;
    reg data_in = 0;
    reg begin_input = 0;
    reg begin_output = 0;
    wire data_out, input_ready, output_ready;

    integer block_number, sample, component, bit_index, bit_count;
    integer value;
    reg [WIDTH-1:0] received_word;
    reg signed [WIDTH-1:0] signed_word;

    always #5 clk = ~clk;

    fft #(
        .INTEGER_WIDTH(8),
        .DECIMAL_WIDTH(8),
        .BLOCK_SIZE_POWER(POWER)
    ) dut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .begin_input(begin_input),
        .begin_output(begin_output),
        .data_out(data_out),
        .input_ready(input_ready),
        .output_ready(output_ready)
    );

    function automatic integer sample_value(input integer block_id, input integer index, input integer imag);
        reg [31:0] noise;
        real phase;
        begin
            if (block_id >= BASE_BLOCKS && block_id < BASE_BLOCKS + SIZE) begin
                phase = 6.283185307179586 * (block_id - BASE_BLOCKS) * index / SIZE;
                sample_value = imag ? 0 : $rtoi($floor(32.0 * $sin(phase) + 0.500000001));
            end else if (block_id >= BASE_BLOCKS + SIZE) begin
                noise = 32'h12345678 ^ ((block_id - BASE_BLOCKS - SIZE) * 32'h9e3779b9)
                    ^ (index * 32'h85ebca6b) ^ (imag * 32'hc2b2ae35);
                noise = (noise ^ (noise >> 16)) * 32'h7feb352d;
                noise = (noise ^ (noise >> 15)) * 32'h846ca68b;
                noise = noise ^ (noise >> 16);
                sample_value = $signed({1'b0, noise[6:0]}) - 64;
            end else case (block_id)
                0: sample_value = (index == 0 && !imag) ? 512 : 0;
                1: sample_value = (index == 1 && !imag) ? 256 : 0;
                2: sample_value = imag ? 0 : 31;
                3: begin
                    case (index % 4)
                        0: sample_value = imag ? 0 : 48;
                        1: sample_value = imag ? 48 : 0;
                        2: sample_value = imag ? 0 : -48;
                        3: sample_value = imag ? -48 : 0;
                    endcase
                end
                4: sample_value = imag ? ((index * 17 + 3) % 83) - 41 :
                                         ((index * 29 + 7) % 97) - 48;
                default: sample_value = 0;
            endcase
        end
    endfunction

    initial begin
        repeat (2) @(negedge clk);
        rst = 0;

        begin_input = 1;
        @(negedge clk);
        begin_input = 0;
        data_in = 1;
        repeat (5) @(negedge clk);
        rst = 1;
        @(negedge clk);
        rst = 0;
        data_in = 0;
        if (!input_ready || output_ready || data_out !== 1'b0)
            $fatal(1, "reset did not abort the partial input transaction");

        // Discard the first result by starting the next input while DONE.
        for (block_number = -1; block_number < BLOCKS; block_number = block_number + 1) begin
            if (!input_ready)
                $fatal(1, "input was not ready for block %0d", block_number);
            begin_input = 1;
            @(negedge clk);
            begin_input = 0;

            for (sample = 0; sample < SIZE; sample = sample + 1) begin
                for (component = 0; component < 2; component = component + 1) begin
                    value = sample_value(block_number, sample, component);
                    for (bit_index = WIDTH - 1; bit_index >= 0; bit_index = bit_index - 1) begin
                        data_in = (value >> bit_index) & 1;
                        @(negedge clk);
                    end
                end
            end
            data_in = 0;
            bit_count = 0;
            while (!output_ready && bit_count < SIZE * POWER * 8 + 20) begin
                @(negedge clk);
                bit_count = bit_count + 1;
            end
            if (!output_ready)
                $fatal(1, "FFT timed out waiting for block %0d", block_number);

            if (block_number >= 0) begin
                begin_output = 1;
                @(negedge clk);
                begin_output = 0;
                @(negedge clk);

                for (sample = 0; sample < SIZE; sample = sample + 1) begin
                    for (component = 0; component < 2; component = component + 1) begin
                        received_word = 0;
                        for (bit_index = 0; bit_index < WIDTH; bit_index = bit_index + 1) begin
                            if (data_out !== 1'b0 && data_out !== 1'b1)
                                $fatal(1, "unknown output bit in block %0d", block_number);
                            received_word = (received_word << 1) | data_out;
                            @(negedge clk);
                        end
                        signed_word = received_word;
                        $display("size=%0d block=%0d sample=%0d component=%0d value=%0d",
                            SIZE, block_number, sample, component, signed_word);
                    end
                end

                if (!input_ready || data_out !== 1'b0)
                    $fatal(1, "FFT did not return to idle after block %0d", block_number);
            end
        end
        $display("fft test completed");
        $finish;
    end

    initial begin
        #1000000000;
        $fatal(1, "FFT test timed out");
    end
endmodule
