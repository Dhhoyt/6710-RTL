module controller_tb;
    localparam integer POWER = 3;
    localparam integer SIZE = 1 << POWER;

    reg clk = 0;
    reg rst = 1;
    reg begin_input = 0;
    reg begin_output = 0;
    reg input_buffer_full = 0;
    reg output_buffer_empty = 0;

    wire mark_data_read;
    wire send_output;
    wire a_write_enable;
    wire b_write_enable;
    wire [POWER:0] address;
    wire [POWER-1:0] angle;
    wire mem_write_enable;
    wire input_ready;
    wire output_ready;
    wire [2:0] mem_input_source;

    integer i;
    integer stage;
    integer butterfly;
    integer operation;
    integer group_index;
    integer within_group;
    integer idx1_expected;
    integer idx2_expected;
    integer angle_expected;
    integer output_sample;
    integer output_reversed;
    integer bit_index;
    integer address_expected;

    always #5 clk = ~clk;

    controller #(
        .BLOCK_SIZE_POWER(POWER),
        .BLOCK_SIZE(SIZE)
    ) dut (
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

    task automatic tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    initial begin
        repeat (2) tick();
        rst = 0;
        tick();
        if (!input_ready)
            $fatal(1, "controller did not become input-ready after reset");

        begin_input = 1;
        tick();
        begin_input = 0;

        for (i = 0; i < SIZE * 2; i = i + 1) begin
            #1;
            if (mem_write_enable || mark_data_read)
                $fatal(1, "input transfer advanced without a full input buffer");
            tick();

            input_buffer_full = 1;
            #1;
            if (!mem_write_enable || !mark_data_read || address != i)
                $fatal(1, "incorrect input transfer at word %0d", i);
            tick();
            input_buffer_full = 0;
        end

        for (stage = 0; stage < POWER; stage = stage + 1) begin
            for (butterfly = 0; butterfly < SIZE / 2; butterfly = butterfly + 1) begin
                group_index = butterfly >> stage;
                within_group = butterfly & ((1 << stage) - 1);
                idx1_expected = (group_index << (stage + 1)) | within_group;
                idx2_expected = idx1_expected + (1 << stage);
                angle_expected = within_group << (POWER - stage - 1);

                for (operation = 0; operation < 8; operation = operation + 1) begin
                    #1;
                    if (angle != angle_expected)
                        $fatal(1, "wrong twiddle angle at stage %0d butterfly %0d", stage, butterfly);
                    case (operation)
                        0: if (!a_write_enable || b_write_enable || mem_write_enable || address != idx1_expected * 2)
                            $fatal(1, "wrong A real load at stage %0d butterfly %0d", stage, butterfly);
                        1: if (!a_write_enable || b_write_enable || mem_write_enable || address != idx1_expected * 2 + 1)
                            $fatal(1, "wrong A imaginary load at stage %0d butterfly %0d", stage, butterfly);
                        2: if (a_write_enable || !b_write_enable || mem_write_enable || address != idx2_expected * 2)
                            $fatal(1, "wrong B real load at stage %0d butterfly %0d", stage, butterfly);
                        3: if (a_write_enable || !b_write_enable || mem_write_enable || address != idx2_expected * 2 + 1)
                            $fatal(1, "wrong B imaginary load at stage %0d butterfly %0d", stage, butterfly);
                        4: if (a_write_enable || b_write_enable || !mem_write_enable ||
                               mem_input_source != 3'b001 || address != idx1_expected * 2)
                            $fatal(1, "wrong A real store at stage %0d butterfly %0d", stage, butterfly);
                        5: if (a_write_enable || b_write_enable || !mem_write_enable ||
                               mem_input_source != 3'b010 || address != idx1_expected * 2 + 1)
                            $fatal(1, "wrong A imaginary store at stage %0d butterfly %0d", stage, butterfly);
                        6: if (a_write_enable || b_write_enable || !mem_write_enable ||
                               mem_input_source != 3'b011 || address != idx2_expected * 2)
                            $fatal(1, "wrong B real store at stage %0d butterfly %0d", stage, butterfly);
                        7: if (a_write_enable || b_write_enable || !mem_write_enable ||
                               mem_input_source != 3'b100 || address != idx2_expected * 2 + 1)
                            $fatal(1, "wrong B imaginary store at stage %0d butterfly %0d", stage, butterfly);
                    endcase
                    tick();
                end
            end
        end

        if (!input_ready || !output_ready)
            $fatal(1, "controller did not signal completion");

        begin_output = 1;
        tick();
        begin_output = 0;
        #1;
        if (send_output)
            $fatal(1, "output transfer advanced while the output buffer was not empty");
        tick();

        output_buffer_empty = 1;
        for (i = 0; i < SIZE * 2; i = i + 1) begin
            output_sample = i >> 1;
            output_reversed = 0;
            for (bit_index = 0; bit_index < POWER; bit_index = bit_index + 1)
                output_reversed = (output_reversed << 1) | ((output_sample >> bit_index) & 1);
            address_expected = (output_reversed << 1) | (i & 1);
            #1;
            if (!send_output || address != address_expected)
                $fatal(1, "wrong output address at word %0d", i);
            tick();
        end

        if (!input_ready || output_ready)
            $fatal(1, "controller did not return to idle after output");

        $display("controller test passed");
        $finish;
    end
endmodule
