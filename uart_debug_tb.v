`default_nettype none
`timescale 1ns/1ns

module uart_debug_tb;

reg [17:0] addresses_to_read [0:3];
initial begin
    addresses_to_read[0] = 18'h37648;
    addresses_to_read[1] = 18'h00000;
    addresses_to_read[2] = 18'h3ffff;
    addresses_to_read[3] = 18'h1aa55;
end
reg [2:0] next_address = 4;

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
reg [2:0] reg_state = 0;
always @(posedge clk) begin
    if (next_address < 4) begin
        uart_rx_valid <= 1;
        case (reg_state)
            0: uart_rx_data <= {6'b000000, addresses_to_read[next_address[1:0]][17:16]};
            1: uart_rx_data <= addresses_to_read[next_address[1:0]][15:8];
            2: uart_rx_data <= addresses_to_read[next_address[1:0]][7:0];
        endcase
        if (uart_rx_ready) begin
            if (reg_state < 2) reg_state <= reg_state + 1;
            else begin
                reg_state <= 0;
                next_address <= next_address + 1;
            end
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
    .axi_r_data(axi_r_data), .axi_r_valid(axi_r_valid), .axi_r_ready(axi_r_ready)
    // axi write address channel
    // axi write data channel
    // axi write response channel
);

`ifdef SRAM
wire aw_ready;
wire w_ready;
wire b_valid;
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
    .aw_valid(1'b0),
    .aw_ready(aw_ready),
    .aw_addr(18'h000),
    .aw_prot(1'b0),
    // write data channel
    .w_valid(1'b0),
    .w_ready(w_ready),
    .w_data(16'h00),
    .w_strb(2'b00),
    // write response channel
    .b_valid(b_valid),
    .b_ready(1'b0),
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
wire aw_ready;
wire w_ready;
wire b_valid;
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
bram_axi axi(
    // global
    .a_clk(clk),
    .a_rst(1'b1),
    // write address channel
    .aw_valid(1'b0),
    .aw_ready(aw_ready),
    .aw_addr(18'h000),
    .aw_prot(1'b0),
    // write data channel
    .w_valid(1'b0),
    .w_ready(w_ready),
    .w_data(16'h00),
    .w_strb(2'b00),
    // write response channel
    .b_valid(b_valid),
    .b_ready(1'b0),
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
