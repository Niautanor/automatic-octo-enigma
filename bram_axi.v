`ifndef BRAM_AXI
`define BRAM_AXI

`default_nettype none

module bram_axi(
    // global
    input a_clk,
    input a_rst,
    // write address channel
    input aw_valid,
    output reg aw_ready,
    input [17:0] aw_addr,
    input aw_prot,
    // write data channel
    input w_valid,
    output reg w_ready,
    input [15:0] w_data,
    input [1:0] w_strb,
    // write response channel
    output reg b_valid,
    input b_ready,
    output reg [1:0] b_resp,
    // read address channel
    input ar_valid,
    output reg ar_ready,
    input [17:0] ar_addr,
    input ar_prot,
    // read data channel
    output reg r_valid,
    input r_ready,
    output reg [15:0] r_data,
    output reg [1:0] r_resp
);

reg [15:0] memory[0:4095];
initial begin
    $readmemh("bee.hex", memory);
    /*
    memory[12'h648] = 16'h55aa;
    memory[12'h000] = 16'habcd;
    memory[12'hfff] = 16'hbabe;
    memory[12'ha55] = 16'hc0fe;
    */
end

initial aw_ready = 0;
initial w_ready = 0;
initial b_valid = 0;
initial b_resp = 2'b00;

initial ar_ready = 0;
initial r_valid = 0;
initial r_resp = 2'b00;

reg read_accepted = 0;
always @(posedge a_clk) begin
    if (ar_valid & !read_accepted) begin
        read_accepted <= 1;
        ar_ready <= 1;
        r_data <= memory[ar_addr[11:0]];
        r_valid <= 1;
    end
    if (ar_valid & ar_ready) ar_ready <= 0;
    if (r_valid & r_ready) begin
        r_valid <= 0;
        read_accepted <= 0;
    end
end

reg write_accepted = 0;
always @(posedge a_clk) begin
    if (aw_valid & w_valid & !write_accepted) begin
        write_accepted <= 1;
        aw_ready <= 1;
        w_ready <= 1;
        memory[aw_addr[11:0]] <= w_data;
        b_valid <= 1;
    end
    if (aw_valid & aw_ready) aw_ready <= 0;
    if (w_valid & w_ready) w_ready <= 0;
    if (b_valid & b_ready) begin
        b_valid <= 0;
        write_accepted <= 0;
    end
end

endmodule

`endif
