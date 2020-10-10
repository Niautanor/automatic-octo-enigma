`default_nettype none
`timescale 1ns/1ns

module test;

reg [7:0] next_data = 8'h41;
reg data_valid = 1;
wire data_ready;

always @(posedge clk) begin
    if (data_ready) begin
        if (next_data == 8'h57)
            next_data <= 8'h41;
        else
            next_data <= next_data + 1;
    end
end

initial begin
    #100000 data_valid = 0;
    #500000 $finish;

end

reg clk = 0;
always #5 clk = !clk;

wire tx;
uart_tx #(.MAIN_CLK(4), .BAUD(1)) uart(
    .clk(clk),
    .data_in(next_data),
    .data_in_valid(data_valid),
    .data_in_ready(data_ready),
    .tx(tx));

initial begin
    $dumpfile("test.vcd");
    $dumpvars;
end

endmodule
