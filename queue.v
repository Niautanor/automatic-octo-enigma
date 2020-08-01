module queue(input clk, input [7:0] in_data, input in_en, output reg overflow, output reg out_available, output reg [7:0] out_data, input out_ack);

parameter SIZE = 16;
localparam ADDRSIZE = $clog2(SIZE);

initial overflow = 0;

reg [7:0] memory [0:SIZE-1];
reg [ADDRSIZE-1:0] index_wr = 0;
reg [ADDRSIZE-1:0] index_rd = 0;

wire [ADDRSIZE-1:0] index_wr_next = index_wr + 1;
wire nonfull = ((index_wr_next) != index_rd);
wire nonempty = (index_rd != index_wr);

always @(posedge clk) begin
    out_data <= memory[index_rd];
    out_available <= nonempty;

    if (in_en & nonfull) begin
        memory[index_wr] <= in_data;
        index_wr <= index_wr + 1;
    end else if (in_en) overflow <= 1;

    if (out_ack & nonempty) begin
        index_rd <= index_rd + 1;
    end
end

endmodule
