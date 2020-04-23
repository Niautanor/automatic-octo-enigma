`timescale 1ns/1ns

module test;

reg rst = 0;
initial begin
    rst = 1;
    #200 rst = 0;
    #100000 rst = 1;
    #200 rst = 0;
    #100000 $finish;

end

reg clk = 0;
always #5 clk = !clk;

wire tx;
uart_tx uart(clk, tx);

initial begin
    $dumpfile("test.vcd");
    $dumpvars(0, tx);
end

endmodule
