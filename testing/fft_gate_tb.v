`timescale 1ns/1ps
// Self-checking testbench shared by the production RTL top and mapped netlist.
// x[0]=1.0+j0 has a constant spectrum: every bin is 1.0+j0.  This checks the
// complete 256-sample serial input, 256-point transform control, and output.
module fft_gate_tb;
    localparam integer WIDTH = 16;
    localparam integer SIZE = 256;
    reg clk = 0;
    reg rst = 1;
    reg data_in = 0;
    reg begin_input = 0;
    reg begin_output = 0;
    wire data_out, input_ready, output_ready;
    integer sample, component, bit_index, wait_count;
    reg [WIDTH-1:0] received_word;
    reg [WIDTH-1:0] expected_word;

    always #5 clk = ~clk;

    fft dut (
        .clk(clk), .rst(rst), .data_in(data_in),
        .begin_input(begin_input), .begin_output(begin_output),
        .data_out(data_out), .input_ready(input_ready), .output_ready(output_ready)
    );

    task send_word(input [WIDTH-1:0] word);
        integer i;
        begin
            for (i = WIDTH - 1; i >= 0; i = i - 1) begin
                data_in = word[i];
                @(negedge clk);
            end
        end
    endtask

    initial begin
        repeat (2) @(negedge clk);
        rst = 0;
        @(negedge clk);
        if (!input_ready) $fatal(1, "input_ready did not assert after reset");

        begin_input = 1;
        @(negedge clk);
        begin_input = 0;
        // Input x[0] = 1.0 + j0, all other complex samples are zero.
        for (sample = 0; sample < SIZE; sample = sample + 1) begin
            send_word(sample == 0 ? 16'h0100 : 16'h0000);
            send_word(16'h0000);
        end
        data_in = 0;

        wait_count = 0;
        while (!output_ready && wait_count < 20000) begin
            @(negedge clk);
            wait_count = wait_count + 1;
        end
        if (!output_ready) $fatal(1, "timed out waiting for FFT result");

        begin_output = 1;
        @(negedge clk);
        begin_output = 0;
        @(negedge clk);
        for (sample = 0; sample < SIZE; sample = sample + 1) begin
            for (component = 0; component < 2; component = component + 1) begin
                received_word = 0;
                for (bit_index = 0; bit_index < WIDTH; bit_index = bit_index + 1) begin
                    if (data_out !== 1'b0 && data_out !== 1'b1)
                        $fatal(1, "unknown output bit at bin %0d component %0d", sample, component);
                    received_word = (received_word << 1) | data_out;
                    @(negedge clk);
                end
                expected_word = component == 0 ? 16'h0100 : 16'h0000;
                if (received_word !== expected_word)
                    $fatal(1, "bin %0d component %0d: got %h, expected %h",
                        sample, component, received_word, expected_word);
                $display("CHECK bin=%0d component=%0d value=%h expected=%h PASS",
                    sample, component, received_word, expected_word);
            end
        end
        $display("FFT_GATE_TEST_PASS: all 512 output words matched the RTL reference.");
        $finish;
    end

    initial begin
        #1000000;
        $fatal(1, "testbench timeout");
    end
endmodule
