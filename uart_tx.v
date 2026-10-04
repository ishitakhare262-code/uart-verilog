module uart_tx #(parameter CLKS_PER_BIT = 434)(
    input  wire       clk,
    input  wire       rst,
    input  wire       tx_start,
    input  wire [7:0] tx_data,
    output reg        tx,
    output reg        tx_busy
);
    localparam IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;

    reg [1:0]  state;
    reg [15:0] clk_cnt;
    reg [2:0]  bit_idx;
    reg [7:0]  data_reg;

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE; tx <= 1'b1; tx_busy <= 1'b0;
            clk_cnt <= 0;  bit_idx <= 0;
        end else begin
            case (state)
                IDLE: begin
                    tx <= 1'b1; clk_cnt <= 0; bit_idx <= 0;
                    if (tx_start) begin
                        data_reg <= tx_data;
                        tx_busy  <= 1'b1;
                        state    <= START;
                    end else tx_busy <= 1'b0;
                end
                START: begin
                    tx <= 1'b0;
                    if (clk_cnt == CLKS_PER_BIT-1) begin
                        clk_cnt <= 0; state <= DATA;
                    end else clk_cnt <= clk_cnt + 1;
                end
                DATA: begin
                    tx <= data_reg[bit_idx];
                    if (clk_cnt == CLKS_PER_BIT-1) begin
                        clk_cnt <= 0;
                        if (bit_idx == 7) state <= STOP;
                        else bit_idx <= bit_idx + 1;
                    end else clk_cnt <= clk_cnt + 1;
                end
                STOP: begin
                    tx <= 1'b1;
                    if (clk_cnt == CLKS_PER_BIT-1) begin
                        clk_cnt <= 0; state <= IDLE; tx_busy <= 1'b0;
                    end else clk_cnt <= clk_cnt + 1;
                end
            endcase
        end
    end
endmodule