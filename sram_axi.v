`default_nettype none

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
    output [1:0] b_resp,
    // read address channel
    input ar_valid,
    output reg ar_ready,
    input [17:0] ar_addr,
    input ar_prot,
    // read data channel
    output r_valid,
    input r_ready,
    output [15:0] r_data,
    output [1:0] r_resp,
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

assign b_resp = 2'b00;
assign r_resp = 2'b00;

wire read_overflow;
skidbuffer #(.DATA_SIZE(16),.FIFO_DEPTH(5)) read_skidbuffer (
    .clk(a_clk),
    .out_ready(r_ready),
    .out_valid(r_valid),
    .out_data(r_data),
    .in_valid(sram_rd_data_vld),
    .in_data(sram_rd_data),
    .overflow(read_overflow)
);

initial aw_ready = 0;
initial w_ready = 0;
initial ar_ready = 0;
initial b_valid = 0;
initial sram_req = 0;
initial sram_rd = 0;
initial sram_addr = 0;
initial sram_wr_data = 0;

wire acceptable_write = aw_valid & w_valid & !sram_req;
wire acceptable_read = ar_valid & !sram_req;

always @(posedge a_clk) begin
    // reset driven valid/ready signals unless they are set again later down
    // I think for performance reasons, I should probably change a*_ready and
    // w_ready to be combinatorical so that they don't lag behind completing
    // a transaction by one cycle
    aw_ready <= 0;
    w_ready <= 0;
    if (b_ready) b_valid <= 0;
    ar_ready <= 0;

    if (acceptable_write) begin
        aw_ready <= 1;
        w_ready <= 1;

        sram_rd <= 0;
        sram_req <= 1;
        sram_be <= w_strb;

        sram_addr <= aw_addr;
        sram_wr_data <= w_data;
    end
    if (acceptable_read) begin
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
end

`ifdef FORMAL
    reg past_valid = 0;
    always @(posedge a_clk) past_valid <= 1;

    // by counting how many transactions we are currently processing, we can
    // make sure that we don't lose anything by asserting that we can never
    // process more than n transactions. In practice, this still makes it
    // possible that we could lose that many transactions but we would reach
    // a stable state eventually and I think it would be difficult to construct
    // a system that isn't there at the start. Maybe there is a way to create
    // some kind of liveness property that says that the (zero transactions in
    // flight) state should be reachable from everywhere but I won't bother with
    // that for now.
    integer ar_in_flight = 0;
    always @(posedge a_clk) begin
        if (ar_valid & ar_ready) ar_in_flight <= ar_in_flight + 1;

        if (r_valid & r_ready) begin
            assert(ar_in_flight > 0);
            ar_in_flight <= ar_in_flight - 1;
        end
    end

    // integer aw_in_flight = 0;
    // integer w_in_flight = 0;
    // always @(posedge a_clk) begin
    // end

    always @(*) begin
        assert(!read_overflow);
        assert(ar_in_flight < 6);
    end
`endif

endmodule
