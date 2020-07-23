module to_hex(input clk, input [7:0] rx_data, input rx_rdy, input tx_rdy, output reg [7:0] tx_data, output reg tx_en);

reg [3:0] buffer = 0;
reg [1:0] state = 0;

always @(posedge clk) begin
    // always reset tx_en unless overridden
    tx_en <= 0;

    case (state)
        0: begin
            if (rx_rdy) begin
                buffer <= rx_data[3:0];
                tx_data <= {4'b0000, rx_data[7:4]} + ((rx_data[7:4] < 10) ? "0" : ("A" - 10));
                tx_en <= 1;
                state <= 1;
            end
        end
        1: begin
            if (tx_rdy) begin
                tx_data <= {4'b0000, buffer} + ((buffer < 10) ? "0" : ("A" - 10));
                tx_en <= 1;
                state <= 2;
            end
        end
        2: begin
            if (tx_rdy) begin
                state <= 0;
            end
        end
    endcase
end

endmodule
