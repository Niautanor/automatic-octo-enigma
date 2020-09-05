`timescale 1ns/100ps
`default_nettype none

module sram_axi_tb();

reg a_clk = 0;
reg a_rst = 0;

always @(posedge a_clk) a_rst <= 1;
always #5 a_clk = !a_clk;

reg aw_valid = 0;
wire aw_ready;
reg [17:0] aw_addr = 0;
reg aw_prot = 0;

reg w_valid = 0;
wire w_ready;
reg [15:0] w_data = 0;
reg [1:0] w_strb = 2'b11;

wire b_valid;
reg b_ready = 1;
wire b_resp;

reg ar_valid = 0;
wire ar_ready;
reg [17:0] ar_addr = 0;
reg ar_prot = 0;

wire r_valid;
reg r_ready = 1;
wire [15:0] r_data;
wire r_resp;

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

always @(posedge a_clk) begin
    if (aw_ready) begin
        aw_valid <= 0;
        aw_addr <= 0;
    end
    if (w_ready) begin
        w_valid <= 0;
        w_data <= 0;
    end
    if (ar_ready) begin
        //ar_valid <= 0;
        ar_addr <= ar_addr + 1;
    end
end

initial begin
    $dumpfile("waves.vcd");
    $dumpvars(0);
    //repeat(1) @(posedge a_clk);
    ar_valid = 1;
    repeat(100) @(posedge a_clk);
    /*
    aw_valid = 1;
    aw_addr = 18'h5;
    w_valid = 1;
    w_data = 16'hab03;
    repeat(10) @(posedge a_clk);
    ar_valid = 1;
    ar_addr = 18'h8;
    repeat(10) @(posedge a_clk);
    */
    $finish;
end

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

// Lamest SRAM simulation model ever: for read operations, return the address...
assign DAT[7:0]  = (!RAMCS && !RAMOE && RAMWE && !RAMLB) ? ADR[7:0] : {8{1'bz}};
assign DAT[15:8] = (!RAMCS && !RAMOE && RAMWE && !RAMUB) ? ADR[15:8] : {8{1'bz}};

endmodule
