module bram_test(input clk, output reg [7:0] data);

reg [7:0] memory [0:63][0:3];
initial $readmemh("bram_test.hex", memory);

reg [6:0] addr = 0;
always @(posedge clk) begin
    addr <= addr + 1;
end

always @(posedge clk) begin
    data <= memory[{addr[0], addr[5:0]}][addr[1:0]];
end
endmodule
