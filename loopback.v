`include "uart_tx.v"
`include "uart_rx.v"

`default_nettype none

module loopback(input clk, input rx, output tx, output [3:0] leds);

localparam BAUD = 9600;

wire rx_ready;
wire [7:0] rx_data;
wire tx_ready;

reg [7:0] fifo = 0;
reg fifo_avail = 0;
always @(posedge clk) begin
    if (tx_ready) fifo_avail <= 0;
    if (rx_ready) begin
        fifo <= rx_data;
        fifo_avail <= 1;
    end
end

assign leds[0] = fifo_avail;
assign leds[1] = rx_ready;
assign leds[2] = tx_ready;
assign leds[3] = fifo[0];

uart_rx #(.BAUD(BAUD)) rx_ctl (.clk(clk), .data_ready(rx_ready), .data(rx_data), .rx(rx));
uart_tx #(.BAUD(BAUD)) tx_ctl (.clk(clk), .rst(0), .en(fifo_avail), .data_in(rx_data), .rdy(tx_ready), .tx(tx));

endmodule
