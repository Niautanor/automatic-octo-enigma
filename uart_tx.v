module uart_tx (input clk, input en, input [7:0] data_in, output reg ack, output reg tx);

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

initial ack = 0;

always @(state) begin
    case (state)
        0: tx = 1; // idle
        1: tx = 0; // start bit
        10: tx = 1; // pause between bytes to allow for resync because I'm a pussy :P
        default: tx = data[state-2];
    endcase
end

always @(posedge clk) begin
    ack <= 0;

    if (idle && en) begin
        div <= 0;
        state <= 1;
        data <= data_in;
        ack <= 1;
    end else if (!idle && txclk) begin
        div <= 0;
        if (state < 10) begin
            state <= state + 1;
        end else begin
            state <= 0; // go back to idle
        end
    end else begin
        div <= div + 1;
    end
end

endmodule
