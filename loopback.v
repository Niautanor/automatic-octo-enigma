`include "uart_tx.v"
`include "uart_rx.v"
`include "to_hex.v"
`include "queue.v"

`default_nettype none

module loopback(input clk, input rx, output tx, output [3:0] leds);

localparam BAUD = 9600;

reg rx0 = 1;
reg rx1 = 1;

always @(posedge clk) begin
    rx0 <= rx;
    rx1 <= rx0;
end
// SB_IO #(
//     .PIN_TYPE(6'b 0000_00),
//     .PULLUP(1'b 1)
// ) sb_io (
//     .INPUT_CLK(clk),
//     .CLOCK_ENABLE(1'b1),
//     .PACKAGE_PIN(rx),
//     .D_IN_0(rx1),
// );


wire rx_ready;
wire [7:0] rx_data;
wire hexin_en;
wire [7:0] hexin_data;
wire hexin_ack;
wire tx_enable;
wire [7:0] tx_data;
wire tx_ack;

reg [2:0] bytes_received = 0;

always @(posedge clk) begin
    if (rx_ready) bytes_received <= bytes_received + 1;
end

assign leds[2:0] = bytes_received;

uart_rx #(.BAUD(BAUD)) rx_ctl (.clk(clk), .data_ready(rx_ready), .data(rx_data), .rx(rx1));

queue q(.clk(clk), .in_data(rx_data), .in_en(rx_ready), .overflow(leds[3]), .out_available(hexin_en), .out_data(hexin_data), .out_ack(hexin_ack));

to_hex hex(.clk(clk), .rx_data(hexin_data), .rx_rdy(hexin_en), .rx_ack(hexin_ack), .tx_ack(tx_ack), .tx_data(tx_data), .tx_en(tx_enable));

uart_tx #(.BAUD(BAUD)) tx_ctl (.clk(clk), .rst(0), .en(tx_enable), .data_in(tx_data), .ack(tx_ack), .tx(tx));

endmodule
