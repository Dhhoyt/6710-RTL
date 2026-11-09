module test_protocol_tb;
    parameter integer WIDTH = 16;
    localparam integer POWER = 3;
    localparam integer SIZE = 1 << POWER;
    localparam integer TOTAL_BITS = SIZE * 2 * WIDTH;

    reg clk = 0;
    reg rst = 1;
    reg data_in = 0;
    reg begin_input = 0;
    reg begin_output = 0;
    wire data_out, input_ready, output_ready;
    integer i;

    always #5 clk = ~clk;

    fft #(
        .INTEGER_WIDTH(WIDTH - 4),
        .DECIMAL_WIDTH(4),
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

    function automatic integer impulse_bit(input integer index);
        integer word_index;
        integer shift;
        begin
            word_index = index / WIDTH;
            shift = WIDTH - 1 - index % WIDTH;
            impulse_bit = (word_index < 2) ? ((32 >> shift) & 1) : 0;
        end
    endfunction

    task automatic reset_fft;
        begin
            rst = 1;
            begin_input = 0;
            begin_output = 0;
            data_in = 0;
            @(negedge clk);
            rst = 0;
            #1;
            if (input_ready !== 1 || output_ready !== 0 || data_out !== 0)
                $fatal(1, "reset did not return interface to idle");
        end
    endtask

    task automatic start_input(input integer simultaneous);
        begin
            if (input_ready !== 1)
                $fatal(1, "input not ready");
            begin_input = 1;
            begin_output = simultaneous;
            @(negedge clk);
            begin_input = 0;
            begin_output = 0;
            #1;
            if (input_ready !== 0 || output_ready !== 0 || data_out !== 0)
                $fatal(1, "input request was not accepted or did not take priority");
        end
    endtask

    task automatic send_input(input integer first_bit, input integer inject_busy_requests);
        integer bit_number;
        begin
            for (bit_number = first_bit; bit_number < TOTAL_BITS; bit_number = bit_number + 1) begin
                data_in = impulse_bit(bit_number);
                begin_input = inject_busy_requests && bit_number == 10;
                begin_output = inject_busy_requests && bit_number == 10;
                @(negedge clk);
                #1;
                if (input_ready !== 0 || output_ready !== 0 || data_out !== 0)
                    $fatal(1, "unexpected interface activity during input bit %0d", bit_number);
            end
            data_in = 0;
            begin_input = 0;
            begin_output = 0;
        end
    endtask

    task automatic wait_for_output(input integer inject_busy_requests);
        integer cycles;
        begin
            cycles = 0;
            while (output_ready !== 1 && cycles < SIZE * POWER * 8 + 20) begin
                begin_input = inject_busy_requests && cycles == 4;
                begin_output = inject_busy_requests && cycles == 4;
                @(negedge clk);
                #1;
                if (input_ready === 1 && output_ready !== 1)
                    $fatal(1, "input became ready during processing");
                if (data_out !== 0)
                    $fatal(1, "unexpected output during processing");
                cycles = cycles + 1;
            end
            begin_input = 0;
            begin_output = 0;
            if (output_ready !== 1 || input_ready !== 1)
                $fatal(1, "FFT failed to complete");
        end
    endtask

    task automatic start_output;
        begin
            if (output_ready !== 1)
                $fatal(1, "output not ready");
            begin_output = 1;
            @(negedge clk);
            begin_output = 0;
            @(negedge clk);
            #1;
        end
    endtask

    task automatic receive_impulse(input integer overlap_input);
        integer bit_number;
        integer expected_bit;
        begin
            for (bit_number = 0; bit_number < TOTAL_BITS; bit_number = bit_number + 1) begin
                expected_bit = (32 >> (WIDTH - 1 - bit_number % WIDTH)) & 1;
                if (data_out !== expected_bit)
                    $fatal(1, "wrong serial output at bit %0d: expected %0d, got %b",
                        bit_number, expected_bit, data_out);
                if (bit_number == 3) begin
                    begin_input = 1;
                    begin_output = 1;
                end else begin
                    begin_input = 0;
                    begin_output = 0;
                end
                if (overlap_input && bit_number == TOTAL_BITS - WIDTH) begin
                    if (input_ready !== 1)
                        $fatal(1, "input not ready while last output word is transmitting");
                    begin_input = 1;
                end
                if (overlap_input && bit_number > TOTAL_BITS - WIDTH)
                    data_in = impulse_bit(bit_number - (TOTAL_BITS - WIDTH) - 1);
                @(negedge clk);
                #1;
            end
            begin_input = 0;
            begin_output = 0;
            if (data_out !== 0)
                $fatal(1, "output did not return to idle");
        end
    endtask

    initial begin
        repeat (2) @(negedge clk);
        reset_fft();

        begin_output = 1;
        @(negedge clk);
        begin_output = 0;
        #1;
        if (input_ready !== 1 || output_ready !== 0 || data_out !== 0)
            $fatal(1, "output request was accepted while not ready");

        start_input(0);
        data_in = 1;
        repeat (5) @(negedge clk);
        reset_fft();

        start_input(0);
        send_input(0, 1);
        wait_for_output(1);
        repeat (3) begin
            @(negedge clk);
            #1;
            if (input_ready !== 1 || output_ready !== 1 || data_out !== 0)
                $fatal(1, "result did not remain ready");
        end

        start_input(1);
        send_input(0, 0);
        wait_for_output(0);
        start_output();
        receive_impulse(1);

        send_input(WIDTH - 1, 0);
        wait_for_output(0);
        start_output();
        receive_impulse(0);

        start_input(0);
        send_input(0, 0);
        repeat (8) @(negedge clk);
        if (output_ready !== 0 || input_ready !== 0)
            $fatal(1, "expected FFT processing before reset");
        reset_fft();

        start_input(0);
        send_input(0, 0);
        wait_for_output(0);
        start_output();
        i = 0;
        while (data_out !== 1 && i < WIDTH) begin
            @(negedge clk);
            #1;
            i = i + 1;
        end
        if (data_out !== 1)
            $fatal(1, "output did not reach a high bit before reset");
        reset_fft();

        start_input(0);
        send_input(0, 0);
        wait_for_output(0);
        start_output();
        receive_impulse(0);

        $display("protocol test completed");
        $finish;
    end

    initial begin
        #1000000;
        $fatal(1, "protocol test timed out");
    end
endmodule
