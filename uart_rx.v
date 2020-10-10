`default_nettype none

module uart_rx(input clk, input rx, output reg [7:0] data, output reg data_valid, input data_ready, output reg overflow);

initial overflow = 0;
initial data_valid = 0;
initial data = 0;
reg [7:0] sr = 0;

parameter MAIN_CLK	= 100000000;
parameter BAUD 		= 115200;

localparam BAUD_DIVIDE  = MAIN_CLK/BAUD;

reg [$clog2(BAUD_DIVIDE+1)-1:0] div = 0;
reg lastrx = 0;
reg idle = 1;
reg [3:0] bitcnt = 0;

/* verilator lint_off WIDTH */
wire halfbaud = div == BAUD_DIVIDE/2;
wire fullbaud = div == BAUD_DIVIDE;
/* verilator lint_on WIDTH */

always @(posedge clk) begin
    lastrx <= rx;
    if (data_ready) data_valid <= 0;
    if (idle) begin
        if (!rx && lastrx) begin
            idle <= 0;
            div <= 0;
            bitcnt <= 0;
            sr <= 0;
        end
    end else begin
        div <= div + 1;
        if (halfbaud) begin
            bitcnt <= bitcnt + 1;
            if (bitcnt == 0) begin
                if (rx) begin
                   // wrong start bit -> ignore
                   idle <= 1;
                end
            end else if (bitcnt == 9) begin
                // we are always back in idle after this
                idle <= 1;
                if (!rx) begin
                    // wrong end bit -> ignore
                end else begin
                    data_valid <= 1;
                    data <= sr;
                    if (data_valid & !data_ready) overflow <= 1;
                end
            end else begin
                // shift in data
                sr <= {rx, sr[7:1]};
            end
        end else if (fullbaud) begin
            div <= 0;
        end
    end
end

endmodule
