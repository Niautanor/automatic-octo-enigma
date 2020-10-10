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

reg [15:0] memory[0:2**18-1];
initial begin
    memory[18'h37648] = 15'h55aa;
    memory[18'h00000] = 16'habcd;
    memory[18'h3ffff] = 16'hbabe;
    memory[18'h2aa55] = 16'hc0fe;
end

initial aw_ready = 0;
initial w_ready = 0;
initial b_valid = 0;
initial b_resp = 2'b00;

initial ar_ready = 0;
initial r_valid = 0;
initial r_data = 16'h0000;
initial r_resp = 2'b00;

reg read_accepted = 0;
always @(posedge a_clk) begin
    if (ar_valid & !read_accepted) begin
        read_accepted <= 1;
        ar_ready <= 1;
        r_data <= memory[ar_addr];
        r_valid <= 1;
    end
    if (ar_valid & ar_ready) ar_ready <= 0;
    if (r_valid & r_ready) begin
        r_valid <= 0;
        read_accepted <= 0;
    end
end

endmodule
