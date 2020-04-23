`timescale 1ns/1ns

module test;

reg [7:0] next_data = 8'h41;
reg en = 0;
wire rdy;

always @(posedge clk) begin
    if (rdy) begin
        en <= 1;
    end else begin
        if (en) begin
            if (next_data == 8'h57)
                next_data <= 8'h41;
            else
                next_data <= next_data + 1;
        end
        en <= 0;
    end
end

reg rst = 0;
initial begin
    rst = 1;
    #200 rst = 0;
    #500000 $finish;

end

reg clk = 0;
always #5 clk = !clk;

wire tx;
uart_tx uart(clk, rst, en, next_data, rdy, tx);

initial begin
    $dumpfile("test.vcd");
    $dumpvars;
end

endmodule
