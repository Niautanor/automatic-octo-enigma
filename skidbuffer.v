`default_nettype none

module skidbuffer #(
        parameter DATA_SIZE=16,
        parameter FIFO_DEPTH = 5) (
    input clk,
    input out_ready,
    output out_valid,
    output [DATA_SIZE-1:0] out_data,
    input in_valid,
    input [DATA_SIZE-1:0] in_data,
    output reg overflow);

reg [$clog2(FIFO_DEPTH+1)-1:0] size = 0;
reg [DATA_SIZE-1:0] queue [0:FIFO_DEPTH-1];
initial overflow = 0;

wire empty = size == 0;
wire full = size == FIFO_DEPTH;

assign out_data = empty ? in_data : queue[0];
assign out_valid = !empty | in_valid;

integer i;

always @(posedge clk) begin
    // if out_ready => shift and decrease size
    // if in_valid => shift and increase size
    // if both => shift and maintain size
    // if none => nothing
    if (out_ready && out_valid) begin
        for (i=0;i<FIFO_DEPTH-1;i=i+1) begin
            queue[i] <= queue[i+1];
        end
        if (!empty)
            size <= size - 1;
    end
    if (in_valid) begin
        if (full) overflow <= 1;
        if (!full) begin
            size <= size + 1;
            queue[size] <= in_data;
        end
    end
    if (out_ready & in_valid) begin
        overflow <= overflow;
        size <= size;
    end
end

`ifdef FORMAL
    reg past_valid = 0;
    always @(posedge clk) past_valid <= 1;

    always @(*) begin
        assert(size <= FIFO_DEPTH);
        if (size == 0) begin
            assert(out_valid == in_valid);
        end
    end
    always @(posedge clk) begin
        if (past_valid & $past(in_valid & !out_ready))
            assert((size == $past(size) + 1) | ($past(full) & overflow & (size == $past(size))));
        if (past_valid & $past(out_ready & !in_valid))
            assert((size == $past(size) - 1) | ($past(empty) & empty & (size == 0)));

        if (overflow & !$past(overflow))
            assert(past_valid & $past(full & in_valid & !out_ready));
        if (past_valid & $past(full & in_valid & !out_ready))
            assert(overflow);
    end
    always @(posedge clk) begin
        if (past_valid & $past(out_valid) & out_valid)
            assert($stable(out_data) | $past(out_ready));
    end

    reg f_was_full = 0;
    always @(posedge clk) if (full) f_was_full <= 1;
    always @(posedge clk) begin
        cover(f_was_full & empty);
    end
`endif

endmodule
