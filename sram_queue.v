`default_nettype none

module sram_queue(
    input clk,
    input [7:0] rx_data,
    input rx_data_vld,
    output reg rx_overflow,
    input sram_ready,
    output reg sram_req,
    output reg sram_rd,
    output [1:0] sram_be,
    input [15:0] sram_rd_data,
    input sram_rd_data_vld,
    output [17:0] sram_addr,
    output reg [15:0] sram_wr_data,
    output [7:0] tx_data,
    output tx_en,
    input tx_ack);

initial rx_overflow = 0;

reg state = 0;
reg state_nxt;

reg [17:0] wraddr = 0;
reg [17:0] rdaddr = 0;
reg [17:0] wraddr_nxt;
reg [17:0] rdaddr_nxt;

assign sram_addr = state ? rdaddr : wraddr;
assign tx_data = sram_rd_data[7:0];

reg rx_overflow_nxt;

wire newline = (rx_data == "\n");

assign tx_en = sram_rd_data_vld;

reg tx_ready = 1;
reg tx_ready_nxt;

assign sram_be = 2'b11;

initial sram_req = 0;
reg sram_req_nxt;

wire sram_busy = sram_req & !sram_ready;

initial sram_wr_data = 0;
reg [15:0] sram_wr_data_nxt;

always @(*) begin
    state_nxt = state;
    wraddr_nxt = wraddr;
    rdaddr_nxt = rdaddr;
    rx_overflow_nxt = rx_overflow;
    tx_ready_nxt = tx_ready;
    sram_req_nxt = sram_req;
    sram_wr_data_nxt = sram_wr_data;

    if (state == 0) begin
        sram_rd = 0;
        // sram has accepted our request
        if (sram_ready) begin
            sram_req_nxt = 0;
            wraddr_nxt = wraddr + 1;
        end

        // new rx data
        if (rx_data_vld) begin
            // actually very likely to occur but just in case
            if (sram_busy) rx_overflow_nxt = 1;

            if (newline) begin
                state_nxt = 1;
                tx_ready_nxt = 1;
            end else if (!sram_busy) begin
                sram_wr_data_nxt = {8'h00, rx_data};
                sram_req_nxt = 1;
            end
        end
    end else begin
        sram_rd = 1;
        if (tx_ack) tx_ready_nxt = 1;
        if (tx_ready) begin
            if (sram_ready) begin
                tx_ready_nxt = 0;
                sram_req = 1;
                rdaddr_nxt = rdaddr + 1;
                if (rdaddr_nxt == wraddr) begin
                    state_nxt = 0;
                    rdaddr_nxt = 0;
                    wraddr_nxt = 0;
                end
            end
        end
    end
end

always @(posedge clk) begin
    state <= state_nxt;
    wraddr <= wraddr_nxt;
    rdaddr <= rdaddr_nxt;
    rx_overflow <= rx_overflow_nxt;
    tx_ready <= tx_ready_nxt;
    sram_req <= sram_req_nxt;
    sram_wr_data <= sram_wr_data_nxt;
end

endmodule
