`timescale 1ns/1ps
module tb_uart_tx;
    localparam CLKS_PER_BIT = 10;
    localparam CLK_PERIOD   = 10;

    reg clk = 0;
    reg rst = 1;
    reg tx_start = 0;
    reg [7:0] tx_data = 0;
    wire tx, tx_busy;

    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) dut (
        .clk(clk), .rst(rst), .tx_start(tx_start), .tx_data(tx_data),
        .tx(tx), .tx_busy(tx_busy)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    reg [7:0] received;
    integer i;

    task send_and_check(input [7:0] byte_to_send);
    begin
        // pulse tx_start for one clock with the data
        @(posedge clk);
        tx_data  <= byte_to_send;
        tx_start <= 1;
        @(posedge clk);
        tx_start <= 0;

        // act as a receiver: wait for the start bit's falling edge
        @(negedge tx);
        repeat (CLKS_PER_BIT/2) @(posedge clk);   // middle of start bit
        if (tx !== 1'b0) $display("FAIL: start bit is not 0");

        // sample each data bit in its middle, LSB first
        for (i = 0; i < 8; i = i + 1) begin
            repeat (CLKS_PER_BIT) @(posedge clk);
            received[i] = tx;
        end

        // check stop bit
        repeat (CLKS_PER_BIT) @(posedge clk);
        if (tx !== 1'b1) $display("FAIL: stop bit is not 1");

        if (received === byte_to_send)
            $display("PASS: sent %h, got %h", byte_to_send, received);
        else
            $display("FAIL: sent %h, got %h", byte_to_send, received);

        wait (tx_busy == 0);   // let the TX finish before the next byte
    end
    endtask

    initial begin
        $dumpfile("uart_tx.vcd");
        $dumpvars(0, tb_uart_tx);
        repeat (3) @(posedge clk);
        rst = 0;
        repeat (2) @(posedge clk);

        send_and_check(8'h41);
        send_and_check(8'hA5);
        send_and_check(8'h00);
        send_and_check(8'hFF);
        $finish;
    end
endmodule