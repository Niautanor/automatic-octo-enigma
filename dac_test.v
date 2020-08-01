module dac_test(input clk, output [1:0] r, output [1:0] g, output [1:0] b);

localparam COUNT = 10000;
localparam WIDTH = $clog2(COUNT-1);

reg [WIDTH-1:0] div = 0;
reg [1:0] intensity = 0;

assign r = intensity;
assign g = intensity;
assign b = intensity;

always @(posedge clk) begin
    div <= div + 1;
    if (div == COUNT - 1) begin
        div <= 0;
        intensity <= intensity + 1;
    end
end

endmodule
