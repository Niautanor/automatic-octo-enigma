`include "uart_tx.v"
`include "uart_rx.v"

`default_nettype none

module loopback(input clk, input rx, output tx, output [3:0] leds);

parameter BAUD = 9600;

reg rx0 = 1;
reg rx1 = 1;

always @(posedge clk) begin
    rx0 <= rx;
    rx1 <= rx0;
end

reg [1:0] bytes_received = 0;

wire rx_valid;
wire rx_ready;
wire [7:0] rx_data;

always @(posedge clk) begin
    if (rx_valid & rx_ready) bytes_received <= bytes_received + 1;
end

assign leds[1:0] = bytes_received;
assign leds[2] = rx_valid & !rx_ready;

uart_rx #(.BAUD(BAUD)) rx_ctl (.clk(clk), .rx(rx1), .data(rx_data), .data_valid(rx_valid), .data_ready(rx_ready), .overflow(leds[3]));

uart_tx #(.BAUD(BAUD)) tx_ctl (.clk(clk), .data_in(rx_data), .data_in_valid(rx_valid), .data_in_ready(rx_ready), .tx(tx));

endmodule
