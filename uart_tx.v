`default_nettype none

module uart_tx (input clk, input [7:0] data_in, input data_in_valid, output data_in_ready, output reg tx);

parameter MAIN_CLK	= 100000000;
parameter BAUD 		= 115200;

localparam BAUD_DIVIDE  = MAIN_CLK/BAUD;

reg [$clog2(BAUD_DIVIDE+1)-1:0] div = 0;

reg [3:0] state = 0;
reg [7:0] data = 8'h00;

/* verilator lint_off WIDTH */
wire txclk = (div == BAUD_DIVIDE);
/* verilator lint_on WIDTH */

wire idle = (state == 0);

always @(state) begin
    case (state)
        0: tx = 1; // idle
        1: tx = 0; // start bit
        10: tx = 1; // stop bit
        default: tx = data[state-2];
    endcase
end

assign data_in_ready = idle | (txclk & (state == 10));

always @(posedge clk) begin
    if (idle && data_in_valid) begin
        div <= 0;
        state <= 1;
        data <= data_in;
    end else if (!idle && txclk) begin
        div <= 0;
        if (state < 10) begin
            state <= state + 1;
        end else if (data_in_valid) begin
            state <= 1;
            data <= data_in;
        end else begin
            state <= 0; // go back to idle
        end
    end else begin
        div <= div + 1;
    end
end

endmodule
