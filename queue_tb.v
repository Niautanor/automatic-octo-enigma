`default_nettype none

module queue_tb(input clk, input [7:0] rx_data, input rx_en, output overflow, output tx);
wire [7:0] tx_data;
wire tx_ack;
wire tx_en;

uart_tx #(.BAUD(1), .MAIN_CLK(1)) tx_ctl(.clk(clk), .rst(1'0), .en(tx_en), .data_in(tx_data), .ack(tx_ack), .tx(tx));

queue #(.SIZE(4)) q(.clk(clk), .in_data(rx_data), .in_en(rx_en), .overflow(overflow), .out_available(tx_en), .out_data(tx_data), .out_ack(tx_ack));
endmodule
