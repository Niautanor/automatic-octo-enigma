`include "uart_tx.v"
`include "uart_rx.v"
`include "to_hex.v"

`default_nettype none

module loopback(input clk, input rx, output tx, output [3:0] leds);

localparam BAUD = 9600;

reg rx0 = 1;
reg rx1 = 1;

always @(posedge clk) begin
    rx0 <= rx;
    rx1 <= rx0;
end

wire rx_ready;
wire [7:0] rx_data;
wire tx_ready;
wire tx_enable;
wire [7:0] tx_data;

reg [3:0] bytes_received = 0;

always @(posedge clk) begin
    if (rx_ready) bytes_received <= bytes_received + 1;
end

assign leds = bytes_received;

uart_rx #(.BAUD(BAUD)) rx_ctl (.clk(clk), .data_ready(rx_ready), .data(rx_data), .rx(rx1));
to_hex hex(.clk(clk), .rx_data(rx_data), .rx_rdy(rx_ready), .tx_rdy(tx_ready), .tx_data, .tx_en(tx_enable));
uart_tx #(.BAUD(BAUD)) tx_ctl (.clk(clk), .rst(0), .en(tx_enable), .data_in(tx_data), .rdy(tx_ready), .tx(tx));

endmodule
