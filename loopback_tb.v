`include "to_hex.v"
`include "uart_tx.v"

module loopback_tb(input clk, input [7:0] rx_data, input rx_en, output overflow, output tx);

wire tx_ack;
wire tx_en;
wire [7:0] tx_data;
wire [7:0] hexin_data;
wire hexin_en;
wire hexin_ack;

uart_tx #(.MAIN_CLK(1), .BAUD(1)) tx_ctl(
    .clk(clk),
    .rst(1'b0),
    .en(tx_en),
    .ack(tx_ack),
    .data_in(tx_data),
    .tx(tx));

to_hex hex(
    .clk(clk),
    .rx_data(hexin_data),
    .rx_rdy(hexin_en),
    .rx_ack(hexin_ack),
    .tx_ack(tx_ack),
    .tx_en(tx_en),
    .tx_data(tx_data));

queue q(
    .clk(clk),
    .in_data(rx_data),
    .in_en(rx_en),
    .overflow(overflow),
    .out_available(hexin_en),
    .out_data(hexin_data),
    .out_ack(hexin_ack));

endmodule
