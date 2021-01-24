`default_nettype none
`timescale 1ns/1ns

`include "uart_debug_top.v"

module uart_debug_tb;

reg [7:0] uart_in [0:21];
initial begin
    uart_in[ 0] = 8'h03;
    uart_in[ 1] = 8'h76;
    uart_in[ 2] = 8'h48;
    uart_in[ 3] = 8'h01;
    uart_in[ 4] = 8'h02;
    uart_in[ 5] = 8'h04;
    uart_in[ 6] = 8'h83;
    uart_in[ 7] = 8'hff;
    uart_in[ 8] = 8'hff;
    uart_in[ 9] = 8'haa;
    uart_in[10] = 8'h55;
    uart_in[11] = 8'h83;
    uart_in[12] = 8'h76;
    uart_in[13] = 8'h48;
    uart_in[14] = 8'hde;
    uart_in[15] = 8'had;
    uart_in[16] = 8'h03;
    uart_in[17] = 8'hff;
    uart_in[18] = 8'hff;
    uart_in[19] = 8'h03;
    uart_in[20] = 8'h76;
    uart_in[21] = 8'h48;
end
integer next_address = 22;

reg [15:0] write_data [0:1];
initial begin
    write_data[0] = 16'haa55;
    write_data[0] = 16'hdead;
end

reg clk = 0;
always #5 clk = !clk;

initial begin
    $dumpfile("uart_debug.vcd");
    $dumpvars;
    #100 next_address = 0;
    #20000 $finish;
end

reg uart_rx_valid = 0;
reg [7:0] uart_rx_data = 0;
wire uart_rx_ready;
always @(posedge clk) begin
    if (next_address == 0) begin
        uart_rx_valid <= 1;
        uart_rx_data <= uart_in[0];
        if (uart_rx_valid & uart_rx_ready) begin
            next_address <= 1;
            uart_rx_data <= uart_in[1];
        end
    end else if (next_address < 21) begin
        if (uart_rx_ready) begin
            next_address <= next_address + 1;
            uart_rx_data <= uart_in[next_address + 1];
        end
    end else begin
        if (uart_rx_ready) uart_rx_valid <= 0;
    end
end

// sram signals
wire RAMCS;
wire RAMWE;
wire RAMOE;
wire RAMLB;
wire RAMUB;
wire [17:0] ADR;
wire [15:0] DAT;

// sram emulation: on read => DAT = lower 16 bits of ADR
assign DAT[7:0]  = (!RAMCS && !RAMOE && RAMWE && !RAMLB) ? ADR[7:0] : {8{1'bz}};
assign DAT[15:8] = (!RAMCS && !RAMOE && RAMWE && !RAMUB) ? ADR[15:8] : {8{1'bz}};

// uart input for top module
wire uart_to_top;
uart_tx #(.MAIN_CLK(2), .BAUD(1)) uart_for_top_ctl(
    .clk(clk), .data_in(uart_rx_data), .data_in_valid(uart_rx_valid), .data_in_ready(uart_rx_ready), .tx(uart_to_top));

// module instantiations
wire uart_from_top;
wire [3:0] leds;
uart_debug_top #(.MAIN_CLK(2), .BAUD(1)) top(
    .clk(clk),
    .rx(uart_to_top),
    .tx(uart_from_top),
    .leds(leds),
    .RAMCS(RAMCS),
    .RAMWE(RAMWE),
    .RAMOE(RAMOE),
    .RAMLB(RAMLB),
    .RAMUB(RAMUB),
    .ADR(ADR),
    .DAT(DAT));
endmodule
