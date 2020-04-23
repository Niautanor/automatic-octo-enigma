module uart_tx (input clk, input rst, input en, input [7:0] data_in, output rdy, output reg tx);

parameter MAIN_CLK	= 100000000;
parameter BAUD 		= 115200;

localparam BAUD_DIVIDE  = MAIN_CLK/BAUD;

reg [$clog2(BAUD_DIVIDE)-1:0] div = 0;

reg [3:0] state = 0;
reg [7:0] data = 8'h00;

wire txclk = (div == BAUD_DIVIDE);

assign rdy = (state == 0);

always @(state) begin
    case (state)
        0: tx = 1; // idle
        1: tx = 0; // start bit
        10: tx = 1; // pause between bytes to allow for resync because I'm a pussy :P
        default: tx = data[state-2];
    endcase
end

always @(posedge clk) begin
    if (rst) begin
        div <= 0;
        state <= 0;
    end else begin
        if (rdy && en) begin
            div <= 0;
            state <= 1;
            data <= data_in;
        end else if (!rdy && txclk) begin
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
end

endmodule
