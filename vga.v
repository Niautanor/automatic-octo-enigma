`default_nettype none

module vga(input clk, output hsync, output vsync, output [1:0] r, output [1:0] g, output [1:0] b);

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

reg [7:0] memory[0:127][0:127];
initial $readmemh("data/image.hex", memory);

reg [7:0] pixel = 0;
always @(posedge clk) begin
    pixel <= memory[x_next][y_next];
end

assign r = pixel[5:4];
assign g = pixel[3:2];
assign b = pixel[1:0];

endmodule
