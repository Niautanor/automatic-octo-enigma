module vga(input clk, output hsync, output vsync, output de);

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

assign de = x < 640 & y < 480;

endmodule
