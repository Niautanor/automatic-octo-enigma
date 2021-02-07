`default_nettype none

`include "palette.v"

module vga(input clk, output hsync, output vsync, output reg [3:0] r, output reg [3:0] g, output reg [3:0] b);

reg [1:0] pixelcnt;
wire pixelclk = (pixelcnt == 3);
always @(posedge clk) pixelcnt <= pixelcnt + 1;

reg [9:0] x = 0;
wire [9:0] x_next = (x == 799) ? 0 : x + 1;
always @(posedge clk) if (pixelclk) x <= x_next;

assign hsync = (x >= (640 + 16) & x < (640 + 16 + 96));

reg [9:0] y = 0;
wire [9:0] y_next = (x == 799) ? (y == 523) ? 0 : y + 1 : y;
always @(posedge clk) if (pixelclk) y <= y_next;

assign vsync = (y >= (480 + 11) & y < (480 + 11 + 2));

reg [5:0] memory[0:127][0:127];
initial $readmemh("data/rabbit.hex", memory);

reg [5:0] pixel_next;
always @(posedge clk) begin
    // TODO: this currently relies on there being at least two clocks between
    // pixel clocks (maybe it even relies on there being three). I should
    // use a pll to clock this at exactly the video clock so that I can actually
    // use real pipelining (in that case, I would need (x|y)_next_next here)
    pixel_next <= memory[y_next[7:1]][x_next[7:1]];
end

wire [3:0] r_next;
wire [3:0] g_next;
wire [3:0] b_next;
palette p(.clk(clk), .pixel(pixel_next), .enable(x < 640 & y < 480), .r(r_next), .g(g_next), .b(b_next));

always @(posedge clk) begin
    if (pixelclk) r <= (x_next < 256 & y_next < 256) ? r_next : 0;
    if (pixelclk) g <= (x_next < 256 & y_next < 256) ? g_next : 0;
    if (pixelclk) b <= (x_next < 256 & y_next < 256) ? b_next : 0;
end

endmodule
