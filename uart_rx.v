module uart_rx #(parameter CLKS_PER_BIT = 434)(
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,
    output reg  [7:0] rx_data,
    output reg        rx_valid
);
    localparam IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;

    // two flip-flops in a row to safely bring the async rx pin into our clock
    reg rx_meta, rx_sync;
    always @(posedge clk) begin
        if (rst) begin
            rx_meta <= 1'b1;
            rx_sync <= 1'b1;
        end else begin
            rx_meta <= rx;
            rx_sync <= rx_meta;
        end
    end

    reg [1:0]  state;
    reg [15:0] clk_cnt;
    reg [2:0]  bit_idx;

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE; clk_cnt <= 0; bit_idx <= 0;
            rx_data <= 8'd0; rx_valid <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    rx_valid <= 1'b0;
                    clk_cnt  <= 0;
                    bit_idx  <= 0;
                    if (rx_sync == 1'b0) state <= START;
                end
                START: begin
                    if (clk_cnt == (CLKS_PER_BIT-1)/2) begin
                        if (rx_sync == 1'b0) begin
                            clk_cnt <= 0;
                            state   <= DATA;
                        end else state <= IDLE;      // glitch, not a real start bit
                    end else clk_cnt <= clk_cnt + 1;
                end
                DATA: begin
                    if (clk_cnt == CLKS_PER_BIT-1) begin
                        clk_cnt <= 0;
                        rx_data[bit_idx] <= rx_sync;
                        if (bit_idx == 7) begin
                            bit_idx <= 0;
                            state   <= STOP;
                        end else bit_idx <= bit_idx + 1;
                    end else clk_cnt <= clk_cnt + 1;
                end
                STOP: begin
                    if (clk_cnt == CLKS_PER_BIT-1) begin
                        if (rx_sync == 1'b1) rx_valid <= 1'b1;   // good stop bit
                        state   <= IDLE;
                    end else clk_cnt <= clk_cnt + 1;
                end
            endcase
        end
    end
endmodule