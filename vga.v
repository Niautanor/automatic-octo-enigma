module vga(input clk, output hsync, output vsync);

reg [1:0] pixelcnt;
wire pixelclk = (pixelcnt == 0);
always @(posedge clk) pixelcnt <= pixelcnt + 1;

reg [9:0] x;
always @(posedge clk) if (pixelclk) begin
    x <= x + 1;
    if (x == 799) x <= 0;
end

assign hsync = x > (640 + 16) && x <= (640 + 16 + 96);

endmodule
