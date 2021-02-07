`default_nettype none

module vga(input clk, output hsync, output vsync, output [3:0] r, output [3:0] g, output [3:0] b);

reg [1:0] pixelcnt;
wire pixelclk = (pixelcnt == 3);
always @(posedge clk) pixelcnt <= pixelcnt + 1;

reg [9:0] x = 0;
wire [9:0] x_next = (x == 799) ? 0 : x + 1;
always @(posedge clk) if (pixelclk) x <= x_next;

assign hsync = x >= (640 + 16) & x < (640 + 16 + 96);

reg [9:0] y = 0;
wire [9:0] y_next = (x == 799) ? (y == 523) ? 0 : y + 1 : y;
always @(posedge clk) if (pixelclk) y <= y_next;

assign vsync = y >= (480 + 11) & y < (480 + 11 + 2);

reg [5:0] memory[0:127][0:127];
initial $readmemh("data/image.hex", memory);

reg [5:0] pixel_next;
reg [5:0] pixel;
always @(posedge clk) begin
    pixel_next <= memory[y_next[7:1]][x_next[7:1]];
    if (pixelclk) pixel <= (x < 256 & y < 256) ? pixel_next : 0;
end

assign r = (x < 640 & y < 480) ? {pixel[5:4], pixel[5:4]} : 0;
assign g = (x < 640 & y < 480) ? {pixel[3:2], pixel[3:2]} : 0;
assign b = (x < 640 & y < 480) ? {pixel[1:0], pixel[1:0]} : 0;

endmodule
