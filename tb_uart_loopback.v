`timescale 1ns/1ps
module tb_uart_loopback;
    localparam CLKS_PER_BIT = 10;
    localparam CLK_PERIOD   = 10;

    reg  clk = 0;
    reg  rst = 1;
    reg  tx_start = 0;
    reg  [7:0] tx_data = 0;
    wire tx_line;          // the single wire connecting TX to RX
    wire tx_busy;
    wire [7:0] rx_data;
    wire rx_valid;

    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_tx (
        .clk(clk), .rst(rst), .tx_start(tx_start), .tx_data(tx_data),
        .tx(tx_line), .tx_busy(tx_busy)
    );

    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_rx (
        .clk(clk), .rst(rst), .rx(tx_line),
        .rx_data(rx_data), .rx_valid(rx_valid)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    integer i;
    integer pass_cnt = 0;
    integer fail_cnt = 0;

    task send_and_check(input [7:0] b);
        integer timeout;
        begin
            // drive one byte into the TX
            @(posedge clk);
            tx_data  <= b;
            tx_start <= 1;
            @(posedge clk);
            tx_start <= 0;

            // wait for the RX to say a byte arrived (with a timeout)
            timeout = 0;
            while (!rx_valid && timeout < 20*CLKS_PER_BIT) begin
                @(posedge clk);
                timeout = timeout + 1;
            end

            // check
            if (!rx_valid) begin
                $display("FAIL: sent %h, RX never produced rx_valid", b);
                fail_cnt = fail_cnt + 1;
            end else if (rx_data !== b) begin
                $display("FAIL: sent %h, got %h", b, rx_data);
                fail_cnt = fail_cnt + 1;
            end else begin
                $display("PASS: sent %h, got %h", b, rx_data);
                pass_cnt = pass_cnt + 1;
            end

            // let TX finish and the line settle before the next byte
            wait (tx_busy == 0);
            repeat (4) @(posedge clk);
        end
    endtask

    initial begin
        $dumpfile("uart_loopback.vcd");
        $dumpvars(0, tb_uart_loopback);

        repeat (3) @(posedge clk);
        rst = 0;
        repeat (2) @(posedge clk);

        // directed corner cases
        send_and_check(8'h00);
        send_and_check(8'hFF);
        send_and_check(8'h55);
        send_and_check(8'hAA);
        send_and_check(8'h01);
        send_and_check(8'h80);
        send_and_check(8'h7F);

        // random bytes
        for (i = 0; i < 50; i = i + 1)
            send_and_check($random);

        if (fail_cnt == 0)
            $display("ALL %0d TESTS PASSED", pass_cnt);
        else
            $display("%0d FAILED, %0d passed", fail_cnt, pass_cnt);
        $finish;
    end
endmodule