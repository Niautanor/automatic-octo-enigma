`default_nettype none

`include "uart_tx.v"
`include "uart_rx.v"
`include "uart_debug.v"

`ifdef SRAM
`include "../BlackIce-II/examples/sram/src/sram_top.v"
`include "../BlackIce-II/examples/sram/src/sram_io_ice40.v"
`include "../BlackIce-II/examples/sram/src/sram_ctrl.v"
`include "sram_axi.v"
`include "skidbuffer.v"
`else
`include "bram_axi.v"
`endif

module uart_debug_top(input clk, input rx, output tx, output [3:0] leds, output RAMCS, output RAMWE, output RAMOE, output RAMLB, output RAMUB, inout [17:0] ADR, inout [15:0] DAT);

parameter BAUD = 9600;

reg rx0 = 1;
reg rx1 = 1;
always @(posedge clk) begin
    rx0 <= rx;
    rx1 <= rx0;
end

wire rx_ready;
wire rx_valid;
wire [7:0] rx_data;
uart_rx #(.BAUD(BAUD)) rx_inst(.clk(clk), .rx(rx1), .data_ready(rx_ready), .data_valid(rx_valid), .data(rx_data), .overflow(leds[0]));

wire tx_ready;
wire tx_valid;
wire [7:0] tx_data;
uart_tx #(.BAUD(BAUD)) tx_inst(.clk(clk), .tx(tx), .data_in_ready(tx_ready), .data_in_valid(tx_valid), .data_in(tx_data));

wire axi_resetn = 1;
wire axi_aw_valid;
wire axi_aw_ready;
wire [17:0] axi_aw_addr;
wire axi_w_valid;
wire axi_w_ready;
wire [15:0] axi_w_data;
wire axi_b_valid;
wire axi_b_ready;
wire axi_ar_valid;
wire axi_ar_ready;
wire [17:0] axi_ar_addr;
wire axi_r_valid;
wire axi_r_ready;
wire [15:0] axi_r_data;
wire [1:0] axi_r_resp;
wire axi_aw_ready;
wire axi_w_ready;
wire axi_b_valid;
wire [1:0] axi_b_resp;

`ifdef SRAM
wire sram_req;
wire sram_ready;
wire sram_rd;
wire [17:0] sram_addr;
wire [1:0] sram_be;
wire [15:0] sram_wr_data;
wire sram_rd_data_vld;
wire [15:0] sram_rd_data;
sram_axi axi(
    .a_clk(clk),
    .a_rst(axi_resetn),
    .aw_valid(axi_aw_valid),
    .aw_ready(axi_aw_ready),
    .aw_addr(axi_aw_addr),
    .aw_prot('0),
    .w_valid(axi_w_valid),
    .w_ready(axi_w_ready),
    .w_data(axi_w_data),
    .w_strb('0),
    .b_valid(axi_b_valid),
    .b_ready(axi_b_ready),
    .b_resp(axi_b_resp),
    .ar_valid(axi_ar_valid),
    .ar_ready(axi_ar_ready),
    .ar_addr(axi_ar_addr),
    .ar_prot('0),
    .r_valid(axi_r_valid),
    .r_ready(axi_r_ready),
    .r_data(axi_r_data),
    .r_resp(axi_r_resp),
    // sram control signals
    .sram_req(sram_req),
    .sram_ready(sram_ready),
    .sram_rd(sram_rd),
    .sram_addr(sram_addr),
    .sram_be(sram_be),
    .sram_wr_data(sram_wr_data),
    .sram_rd_data_vld(sram_rd_data_vld),
    .sram_rd_data(sram_rd_data)
);

reg sram_reset = 0;
always @(posedge clk) sram_reset <= 1;

sram_top sram(
	.clk(clk),
	.reset_(sram_reset),
	// SRAM core issue interface
	.sram_req(sram_req),
	.sram_ready(sram_ready),
	.sram_rd(sram_rd),
	.sram_addr(sram_addr),
	.sram_be(sram_be),
	.sram_wr_data(sram_wr_data),

	// SRAM core read data interface
	.sram_rd_data_vld(sram_rd_data_vld),
	.sram_rd_data(sram_rd_data),

	// IO pins
	.RAMCS(RAMCS),
	.RAMWE(RAMWE),
	.RAMOE(RAMOE),
	.RAMLB(RAMLB),
	.RAMUB(RAMUB),
	.ADR(ADR),
	.DAT(DAT)
);
`else
bram_axi axi(
    .a_clk(clk),
    .a_rst(axi_resetn),
    .aw_valid(axi_aw_valid),
    .aw_ready(axi_aw_ready),
    .aw_addr(axi_aw_addr),
    .aw_prot('0),
    .w_valid(axi_w_valid),
    .w_ready(axi_w_ready),
    .w_data(axi_w_data),
    .w_strb('0),
    .b_valid(axi_b_valid),
    .b_ready(axi_b_ready),
    .b_resp(axi_b_resp),
    .ar_valid(axi_ar_valid),
    .ar_ready(axi_ar_ready),
    .ar_addr(axi_ar_addr),
    .ar_prot('0),
    .r_valid(axi_r_valid),
    .r_ready(axi_r_ready),
    .r_data(axi_r_data),
    .r_resp(axi_r_resp));
`endif

uart_debug debug(
    .clk(clk),
    .uart_rx(rx_data),
    .uart_rx_valid(rx_valid),
    .uart_rx_ready(rx_ready),
    .uart_tx(tx_data),
    .uart_tx_valid(tx_valid),
    .uart_tx_ready(tx_ready),
    .axi_ar_addr(axi_ar_addr),
    .axi_ar_valid(axi_ar_valid),
    .axi_ar_ready(axi_ar_ready),
    .axi_r_data(axi_r_data),
    .axi_r_valid(axi_r_valid),
    .axi_r_ready(axi_r_ready),
    .axi_aw_addr(axi_aw_addr),
    .axi_aw_valid(axi_aw_valid),
    .axi_aw_ready(axi_aw_ready),
    .axi_w_data(axi_w_data),
    .axi_w_valid(axi_w_valid),
    .axi_w_ready(axi_w_ready),
    .axi_b_valid(axi_b_valid),
    .axi_b_ready(axi_b_ready),
    .leds(leds[3:1])
);

endmodule
