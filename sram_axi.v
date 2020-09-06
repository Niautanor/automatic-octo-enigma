/**
 * sram_axi
 *
 * Provide an AXI interface to the Blackice-II example sram core. Since the sram
 * can only handle one transaction at a time, reads are prioritized over writes.
 */
module sram_axi(
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
    output reg b_resp,
    // read address channel
    input ar_valid,
    output reg ar_ready,
    input [17:0] ar_addr,
    input ar_prot,
    // read data channel
    output reg r_valid,
    input r_ready,
    output reg [15:0] r_data,
    output reg r_resp,
    // sram control signals
    output reg sram_req,
    input sram_ready,
    output reg sram_rd,
    output reg [17:0] sram_addr,
    output reg [1:0] sram_be,
    output reg [15:0] sram_wr_data,
    input sram_rd_data_vld,
    input [15:0] sram_rd_data
);

initial aw_ready = 0;
initial w_ready = 0;
initial ar_ready = 0;
initial b_valid = 0;
initial r_valid = 0;
initial r_data = 0;
initial sram_req = 0;
initial sram_rd = 0;
initial sram_addr = 0;
initial sram_wr_data = 0;

reg transaction_in_flight = 0;

wire acceptable_write = aw_valid & w_valid & !sram_req & !transaction_in_flight;
wire acceptable_read = ar_valid & !sram_req & !transaction_in_flight;

always @(posedge a_clk) begin
    // reset driven valid/ready signals unless they are set again later down
    // I think for performance reasons, I should probably change a*_ready and
    // w_ready to be combinatorical so that they don't lag behind completing
    // a transaction by one cycle
    aw_ready <= 0;
    w_ready <= 0;
    if (b_ready) begin
        if (b_valid) transaction_in_flight <= 0;
        b_valid <= 0;
    end
    ar_ready <= 0;
    if (r_ready) begin
        if (r_valid) transaction_in_flight <= 0;
        r_valid <= 0;
    end

    if (acceptable_write) begin
        transaction_in_flight <= 1;

        aw_ready <= 1;
        w_ready <= 1;

        sram_rd <= 0;
        sram_req <= 1;
        sram_be <= w_strb;

        sram_addr <= aw_addr;
        sram_wr_data <= w_data;
    end
    if (acceptable_read) begin
        transaction_in_flight <= 1;

        ar_ready <= 1;
        // need to undo accepting the write transaction if there was one
        aw_ready <= 0;
        w_ready <= 0;

        sram_rd <= 1;
        sram_req <= 1;
        sram_be <= 2'b11;

        sram_addr <= ar_addr;
    end
    if (sram_req & sram_ready) begin
        sram_req <= 0;

        if (!sram_rd) begin
            b_valid <= 1;
            // if this was a write transaction, we have to send a respone here.
        end
    end
    if (sram_rd_data_vld) begin
        // we got data from the sram which was probably related to a previous
        // read transaction. There's no way to check here so we don't have to
        // worry :P
        r_valid <= 1;
        r_data <= sram_rd_data;
    end
end

endmodule
