`include "loopback.v"

module loopback_tb(input clk, input [7:0] rx_data, input rx_valid, output rx_ready, output [3:0] leds, output tx);

parameter BAUD = 10000;

wire rx;
uart_tx #(.BAUD(BAUD)) tx_inst(.clk(clk), .data_in(rx_data), .data_in_valid(rx_valid), .data_in_ready(rx_ready), .tx(rx));

loopback #(.BAUD(BAUD)) loopback_inst(.clk(clk), .rx(rx), .tx(tx), .leds(leds));

endmodule
