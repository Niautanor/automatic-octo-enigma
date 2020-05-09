module uart_rx(input clk, input rx, output reg data_ready, output reg [7:0] data);

initial data_ready = 0;
initial data = 0;

parameter MAIN_CLK	= 100000000;
parameter BAUD 		= 115200;

localparam BAUD_DIVIDE  = MAIN_CLK/BAUD;

reg [$clog2(BAUD_DIVIDE)-1:0] div = 0;
reg lastrx = 0;
reg idle = 1;
reg [3:0] bitcnt = 0;

always @(posedge clk) begin
    lastrx <= rx;
    if (idle) begin
        data_ready <= 0;
        if (!rx && lastrx) begin
            idle <= 0;
            div <= 0;
            bitcnt <= 0;
            data <= 0;
        end
    end else begin
        div <= div + 1;
        if (div == (BAUD_DIVIDE / 2)) begin
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
                    data_ready <= 1;
                end
            end else begin
                // shift in data
                data <= {rx, data[7:1]};
            end
        end else if (div == BAUD_DIVIDE) begin
            div <= 0;
        end
    end
end

endmodule
