module uart_tx (input clk, input rst, output reg tx);

// TODO: parameterize this
reg [15:0] div = 0;

reg [4:0] state = 0;
reg [7:0] data = 8'h42;

wire txclk = (div == 868);

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
        data <= 8'h42;
    end else begin
        if (txclk) begin
            div <= 0;
            if (state < 10) begin
                state <= state + 1;
            end
        end else begin
            div <= div + 1;
        end
    end
end

endmodule
