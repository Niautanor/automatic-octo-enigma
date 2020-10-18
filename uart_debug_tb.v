`default_nettype none
`timescale 1ns/1ns

module uart_debug_tb;

reg [7:0] uart_in [0:21];
initial begin
    uart_in[ 0] = 8'h03;
    uart_in[ 1] = 8'h76;
    uart_in[ 2] = 8'h48;
    uart_in[ 3] = 8'h01;
    uart_in[ 4] = 8'h02;
    uart_in[ 5] = 8'h04;
    uart_in[ 6] = 8'h83;
    uart_in[ 7] = 8'hff;
    uart_in[ 8] = 8'hff;
    uart_in[ 9] = 8'haa;
    uart_in[10] = 8'h55;
    uart_in[11] = 8'h83;
    uart_in[12] = 8'h76;
    uart_in[13] = 8'h48;
    uart_in[14] = 8'hde;
    uart_in[15] = 8'had;
    uart_in[16] = 8'h00;
    uart_in[17] = 8'h00;
    uart_in[18] = 8'h00;
    uart_in[19] = 8'h03;
    uart_in[20] = 8'h76;
    uart_in[21] = 8'h48;
end
integer next_address = 22;

reg [15:0] write_data [0:1];
initial begin
    write_data[0] = 16'haa55;
    write_data[0] = 16'hdead;
end

reg clk = 0;
always #5 clk = !clk;

reg sram_reset = 0;

initial begin
    $dumpfile("uart_debug.vcd");
    $dumpvars;
    #50 sram_reset = 1;
    #100 next_address = 0;
    #20000 $finish;
end

reg uart_rx_valid = 0;
reg [7:0] uart_rx_data = 0;
wire uart_rx_ready;
always @(posedge clk) begin
    if (next_address < 22) begin
        uart_rx_valid <= 1;
        if (uart_rx_ready) begin
            uart_rx_data <= uart_in[next_address];
            next_address <= next_address + 1;
        end
    end else begin
        uart_rx_valid <= 0;
    end
end

// module instantiations
wire tx;
wire uart_tx_valid;
wire uart_tx_ready;
wire [7:0] uart_tx_data;
uart_tx #(.MAIN_CLK(2), .BAUD(1)) tx_inst(
    .clk(clk), .data_in(uart_tx_data), .data_in_valid(uart_tx_valid), .data_in_ready(uart_tx_ready), .tx(tx));

wire [17:0] axi_ar_addr;
wire axi_ar_valid;
wire axi_ar_ready;
wire [15:0] axi_r_data;
wire axi_r_valid;
wire axi_r_ready;
wire [17:0] axi_aw_addr;
wire axi_aw_valid;
wire axi_aw_ready;
wire [15:0] axi_w_data;
wire axi_w_valid;
wire axi_w_ready;
wire axi_b_valid;
wire axi_b_ready;
uart_debug debug(
    .clk(clk),
    // uart rx
    .uart_rx(uart_rx_data), .uart_rx_valid(uart_rx_valid), .uart_rx_ready(uart_rx_ready), 
    // uart tx
    .uart_tx(uart_tx_data), .uart_tx_valid(uart_tx_valid), .uart_tx_ready(uart_tx_ready),
    // TODO: add response signals / masks / prot / whatever
    // axi read address channel
    .axi_ar_addr(axi_ar_addr), .axi_ar_valid(axi_ar_valid), .axi_ar_ready(axi_ar_ready),
    // axi read response channel
    .axi_r_data(axi_r_data), .axi_r_valid(axi_r_valid), .axi_r_ready(axi_r_ready),
    // axi write address channel
    .axi_aw_addr(axi_aw_addr), .axi_aw_valid(axi_aw_valid), .axi_aw_ready(axi_aw_ready),
    // axi write data channel
    .axi_w_data(axi_w_data), .axi_w_valid(axi_w_valid), .axi_w_ready(axi_w_ready),
    // axi write response channel
    .axi_b_valid(axi_b_valid), .axi_b_ready(axi_b_ready)
);

`ifdef SRAM
wire [1:0] b_resp;
wire [1:0] r_resp;
wire sram_req;
wire sram_ready;
wire sram_rd;
wire [17:0] sram_addr;
wire [1:0] sram_be;
wire [15:0] sram_wr_data;
wire sram_rd_data_vld;
wire [15:0]sram_rd_data;
sram_axi axi(
    // global
    .a_clk(clk),
    .a_rst(1'b1),
    // write address channel
    .aw_valid(axi_aw_valid),
    .aw_ready(axi_aw_ready),
    .aw_addr(axi_aw_addr),
    .aw_prot(1'b0),
    // write data channel
    .w_valid(axi_w_valid),
    .w_ready(axi_w_ready),
    .w_data(axi_w_data),
    .w_strb(2'b00),
    // write response channel
    .b_valid(axi_b_valid),
    .b_ready(axi_b_ready),
    .b_resp(b_resp),
    // read address channel
    .ar_valid(axi_ar_valid),
    .ar_ready(axi_ar_ready),
    .ar_addr(axi_ar_addr),
    .ar_prot(1'b0),
    // read data channel
    .r_valid(axi_r_valid),
    .r_ready(axi_r_ready),
    .r_data(axi_r_data),
    .r_resp(r_resp),
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

wire RAMCS;
wire RAMWE;
wire RAMOE;
wire RAMLB;
wire RAMUB;
wire [17:0] ADR;
wire [15:0] DAT;
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

// sram emulation: on read => DAT = lower 16 bits of ADR
assign DAT[7:0]  = (!RAMCS && !RAMOE && RAMWE && !RAMLB) ? ADR[7:0] : {8{1'bz}};
assign DAT[15:8] = (!RAMCS && !RAMOE && RAMWE && !RAMUB) ? ADR[15:8] : {8{1'bz}};
`else
wire [1:0] b_resp;
wire [1:0] r_resp;
bram_axi axi(
    // global
    .a_clk(clk),
    .a_rst(1'b1),
    // write address channel
    .aw_valid(axi_aw_valid),
    .aw_ready(axi_aw_ready),
    .aw_addr(axi_aw_addr),
    .aw_prot(1'b0),
    // write data channel
    .w_valid(axi_w_valid),
    .w_ready(axi_w_ready),
    .w_data(axi_w_data),
    .w_strb(2'b00),
    // write response channel
    .b_valid(axi_b_valid),
    .b_ready(axi_b_ready),
    .b_resp(b_resp),
    // read address channel
    .ar_valid(axi_ar_valid),
    .ar_ready(axi_ar_ready),
    .ar_addr(axi_ar_addr),
    .ar_prot(1'b0),
    // read data channel
    .r_valid(axi_r_valid),
    .r_ready(axi_r_ready),
    .r_data(axi_r_data),
    .r_resp(r_resp)
);
`endif

endmodule
