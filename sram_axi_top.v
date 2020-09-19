module sram_axi_top(
    input a_clk,
    input a_rst,

    input aw_valid,
    output aw_ready,
    input aw_prot,

    input w_valid,
    output w_ready,
    input [15:0] w_data,
    input [1:0] w_strb,

    output b_valid,
    input b_ready,
    output [1:0] b_resp,


    input ar_valid,
    input ar_ready,
    input [17:0] ar_addr,
    input ar_prot,

    output r_valid,
    input r_ready,
    output [17:0] r_data,
    output [1:0] r_resp,
);

wire sram_req;
wire sram_ready;
wire sram_rd;
wire [17:0] sram_addr;
wire [1:0] sram_be;
wire [15:0] sram_wr_data;
wire sram_rd_data_vld;
wire [15:0] sram_rd_data;

wire RAMCS;
wire RAMWE;
wire RAMOE;
wire RAMLB;
wire RAMUB;
wire [17:0] ADR;
wire [15:0] DAT;

sram_top sram(
    .clk(a_clk),
    .reset_(a_rst),
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

sram_axi axi(
    .a_clk(a_clk),
    .a_rst(a_rst),
    .aw_valid(aw_valid),
    .aw_ready(aw_ready),
    .aw_prot(aw_prot),
    .w_valid(w_valid),
    .w_ready(w_ready),
    .w_data(w_data),
    .w_strb(w_strb),
    .b_valid(b_valid),
    .b_ready(b_ready),
    .b_resp(b_resp),
    .ar_valid(ar_valid),
    .ar_ready(ar_ready),
    .ar_addr(ar_addr),
    .ar_prot(ar_prot),
    .r_valid(r_valid),
    .r_ready(r_ready),
    .r_data(r_data),
    .r_resp(r_resp),
    .sram_req(sram_req),
    .sram_ready(sram_ready),
    .sram_rd(sram_rd),
    .sram_addr(sram_addr),
    .sram_be(sram_be),
    .sram_wr_data(sram_wr_data),
    .sram_rd_data_vld(sram_rd_data_vld),
    .sram_rd_data(sram_rd_data));

endmodule
