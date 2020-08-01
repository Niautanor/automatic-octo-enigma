module to_hex(
    input clk,
    input [7:0] rx_data,
    input rx_rdy,
    output reg rx_ack,
    input tx_ack,
    output reg [7:0] tx_data,
    output tx_en);

reg [3:0] buffer = 0;
reg [1:0] state = 0;

assign tx_en = (state != 0);

always @(posedge clk) begin
    // always reset rx_ack unless overridden
    rx_ack <= 0;

    case (state)
        0: begin
            if (rx_rdy) begin
                buffer <= rx_data[3:0];
                tx_data <= {4'b0000, rx_data[7:4]} + ((rx_data[7:4] < 10) ? "0" : ("A" - 10));
                rx_ack <= 1;
                state <= 1;
            end
        end
        1: begin
            if (tx_ack) begin
                tx_data <= {4'b0000, buffer} + ((buffer < 10) ? "0" : ("A" - 10));
                state <= 2;
            end
        end
        2: begin
            if (tx_ack) begin
                state <= 0;
            end
        end
    endcase
end

endmodule
