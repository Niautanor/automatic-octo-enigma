`include "output_pin_with_enable.v"

module vga(input clk, output hsync, output vsync, output [1:0] r, output [1:0] g, output [1:0] b);

reg [1:0] pixelcnt;
wire pixelclk = (pixelcnt == 0);
always @(posedge clk) pixelcnt <= pixelcnt + 1;

reg [9:0] x = 799;
always @(posedge clk) if (pixelclk) begin
    x <= x + 1;
    if (x == 799) x <= 0;
end

assign hsync = x >= (640 + 16) & x < (640 + 16 + 96);

reg [9:0] y = 523;
always @(posedge clk) if (pixelclk & (x == 799)) begin
    y <= y + 1;
    if (y == 523) y <= 0;
end

assign vsync = y >= (480 + 11) & y < (480 + 11 + 2);

wire de = x < 640 & y < 480;

wire [1:0] r_data = x[3:2];
wire [1:0] g_data = x[3:2];
wire [1:0] b_data = x[3:2];

output_pin_with_enable r0 (.data(r_data[0]), .enable(de), .pin(r[0]));
output_pin_with_enable r1 (.data(r_data[1]), .enable(de), .pin(r[1]));
output_pin_with_enable g0 (.data(g_data[0]), .enable(de), .pin(g[0]));
output_pin_with_enable g1 (.data(g_data[1]), .enable(de), .pin(g[1]));
output_pin_with_enable b0 (.data(b_data[0]), .enable(de), .pin(b[0]));
output_pin_with_enable b1 (.data(b_data[1]), .enable(de), .pin(b[1]));

endmodule
