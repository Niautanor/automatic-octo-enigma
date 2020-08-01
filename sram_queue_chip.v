`default_nettype none

`include "sram_queue.v"
`include "uart_tx.v"
`include "uart_rx.v"

module sram_queue_chip(
    input clk,
    output led,
    input rx,
    output tx,
    inout RAMCS,
    inout RAMWE,
    inout RAMOE,
    inout RAMLB,
    inout RAMUB,
    inout [17:0] ADR,
    inout [15:0] DAT
);

parameter BAUD = 115200;

reg rx0 = 1;
reg rx1 = 1;
always @(posedge clk) begin
    rx0 <= rx;
    rx1 <= rx0;
end

wire rx_data_vld;
wire [7:0] rx_data;
uart_rx #(.BAUD(BAUD)) rx_ctl(.clk(clk), .rx(rx1), .data_ready(rx_data_vld), .data(rx_data));

wire [7:0] tx_data;
wire tx_en;
wire tx_ack;
uart_tx #(.BAUD(BAUD)) tx_ctl(.clk(clk), .en(tx_en), .ack(tx_ack), .data_in(tx_data), .tx(tx));

wire        sram_req;
wire        sram_ready;
wire        sram_rd;
wire [17:0] sram_addr;
wire [1:0]  sram_be;
wire [15:0] sram_wr_data;
wire        sram_rd_data_vld;
wire [15:0] sram_rd_data;

// sram controller requires initial reset
reg sram_reset = 0;
always @(posedge clk) sram_reset <= 1;

sram_top sram(
    .clk(clk),
    .reset_(sram_reset),
    .sram_req(sram_req),
    .sram_ready(sram_ready),
    .sram_rd(sram_rd),
    .sram_addr(sram_addr),
    .sram_be(sram_be),
    .sram_wr_data(sram_wr_data),
    .sram_rd_data_vld(sram_rd_data_vld),
    .sram_rd_data(sram_rd_data),
    .RAMCS(RAMCS),
    .RAMWE(RAMWE),
    .RAMOE(RAMOE),
    .RAMLB(RAMLB),
    .RAMUB(RAMUB),
    .ADR(ADR),
    .DAT(DAT));

sram_queue queue(
    .clk(clk),
    .rx_data(rx_data),
    .rx_data_vld(rx_data_vld),
    .rx_overflow(led),
    .sram_ready(sram_ready),
    .sram_req(sram_req),
    .sram_rd(sram_rd),
    .sram_be(sram_be),
    .sram_rd_data(sram_rd_data),
    .sram_rd_data_vld(sram_rd_data_vld),
    .sram_addr(sram_addr),
    .sram_wr_data(sram_wr_data),
    .tx_data(tx_data),
    .tx_en(tx_en),
    .tx_ack(tx_ack));

endmodule
