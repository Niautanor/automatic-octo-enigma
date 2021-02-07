`default_nettype none

/**
 * Vga color palette. Pixel data comes in, color data comes out on the next
 * clock.
 */
module palette #(
        parameter BITS_PER_PIXEL=6,
        parameter BITS_PER_COLOR=4) (
    input clk,
    input [BITS_PER_PIXEL-1:0] pixel,
    input enable,
    output [BITS_PER_COLOR-1:0] r,
    output [BITS_PER_COLOR-1:0] g,
    output [BITS_PER_COLOR-1:0] b);

localparam OUTSIZE = 3*BITS_PER_COLOR;

reg [OUTSIZE-1:0] colorrom[0:2**BITS_PER_PIXEL-1];
reg [OUTSIZE-1:0] out;

initial begin
    $readmemh("data/palette.hex", colorrom);
end

always @(posedge clk) begin
    out <= colorrom[pixel];
end

// does this work?
assign {r, g, b} = enable ? out : OUTSIZE'd0;
//assign r = out[BITS_PER_COLOR-1:0];
//assign g = out[2*BITS_PER_COLOR-1:BITS_PER_COLOR];
//assign b = out[3*BITS_PER_COLOR-1:2*BITS_PER_COLOR];

endmodule
