`timescale 1ns/100ps

`default_nettype none

`include "sram_queue_chip.v"

module sram_queue_tb(
);

wire led;
wire tx;
wire RAMCS;
wire RAMWE;
wire RAMOE;
wire RAMLB;
wire RAMUB;
wire [17:0] ADR;
wire [15:0] DAT;

reg clk = 0;
always #5 clk <= !clk;

initial begin
    $dumpfile("waves.vcd");
    $dumpvars(0);
    repeat(10000) @(posedge clk);
    $finish;
end

parameter BAUD = 50000000;

wire [0:8*13 - 1] text = "Hello World!\n";

wire rx;
integer index = 0;
wire [7:0] tx_data = (index < 13) ? text[index*8+:8] : 8'h00;
wire tx_en = (index < 13);
wire tx_ack;

uart_tx #(.BAUD(BAUD)) tx_gen(.clk(clk), .data_in(tx_data), .en(tx_en), .ack(tx_ack), .tx(rx));

always @(posedge clk) begin
    if (index < 13) begin
        if (tx_ack) begin
            index <= index + 1;
        end
    end else begin
        index <= index + 1;
        if (index == 999) index <= 0;
    end
end

sram_queue_chip #(.BAUD(BAUD)) chip(
    .clk(clk),
    .rx(rx),
    .tx(tx),
    .led(led),
    .RAMCS(RAMCS),
    .RAMWE(RAMWE),
    .RAMOE(RAMOE),
    .RAMLB(RAMLB),
    .RAMUB(RAMUB),
    .ADR(ADR),
    .DAT(DAT));

// Lamest SRAM simulation model ever: for read operations, return the address...
assign DAT[7:0]  = (!RAMCS && !RAMOE && RAMWE && !RAMLB) ? ADR[7:0] : {8{1'bz}};
assign DAT[15:8] = (!RAMCS && !RAMOE && RAMWE && !RAMUB) ? ADR[15:8] : {8{1'bz}};

endmodule
