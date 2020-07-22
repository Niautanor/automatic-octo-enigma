`include "uart_tx.v"
`include "uart_rx.v"

`default_nettype none

module loopback(input clk, input rx, output tx, output reg [3:0] leds);

localparam BAUD = 9600;

wire rx_ready;
wire [7:0] rx_data;

always @(posedge clk) begin
    if (rx_ready) leds <= rx_data[3:0];
end

uart_rx #(.BAUD(BAUD)) rx_ctl (.clk(clk), .data_ready(rx_ready), .data(rx_data), .rx(rx));
uart_tx #(.BAUD(BAUD)) tx_ctl (.clk(clk), .rst(0), .en(rx_ready), .data_in(rx_data), .rdy(), .tx(tx));

endmodule
