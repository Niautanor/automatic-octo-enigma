module uart_debug(
    input clk,
    // uart rx
    input [7:0] uart_rx, input uart_rx_valid, output reg uart_rx_ready, 
    // uart tx
    output reg [7:0] uart_tx, output reg uart_tx_valid, input uart_tx_ready,
    // TODO: add response signals / masks / prot / whatever
    // axi read address channel
    output reg [17:0] axi_ar_addr, output reg axi_ar_valid, input axi_ar_ready,
    // axi read response channel
    input [15:0] axi_r_data, input axi_r_valid, output reg axi_r_ready
    // axi write address channel
    // axi write data channel
    // axi write response channel
);

initial uart_rx_ready = 1;
initial uart_tx_valid = 0;

initial axi_ar_valid = 0;
initial axi_r_ready = 0;

reg [23:0] command_reg = 0;
reg [7:0] uart_tx_next = 0;

integer state = 0;
always @(posedge clk) begin
    case (state)
        0: if (uart_rx_valid) begin
            command_reg[23:16] <= uart_rx;
            state <= 1;
        end
        1: if (uart_rx_valid) begin
            command_reg[15:8] <= uart_rx;
            state <= 2;
        end
        2: if (uart_rx_valid) begin
            command_reg[7:0] <= uart_rx;
            uart_rx_ready <= 0;
            axi_ar_valid <= 1;
            axi_ar_addr <= {command_reg[17:8], uart_rx}; 
            state <= 3;
        end
        3: if (axi_ar_ready) begin
            axi_ar_valid <= 0;
            axi_r_ready <= 1;
            state <= 4;
        end
        4: if (axi_r_valid) begin
            axi_r_ready <= 0;
            uart_tx <= axi_r_data[7:0];
            uart_tx_next <= axi_r_data[15:8];
            uart_tx_valid <= 1;
            state <= 5;
        end
        5: if (uart_tx_ready) begin
            uart_tx <= uart_tx_next;
            state <= 6;
        end
        6: if (uart_tx_ready) begin
            uart_tx_valid <= 0;
            uart_rx_ready <= 1;
            state <= 0;
        end
    endcase
end

// state machine:
// 0 -> idle, wait for byte 0 of command reg on uart rx channel then go to 1
// 1 -> wait for byte 1 of command reg on uart rx channel then go to 2
// 2 -> wait for byte 3 of command reg on uart rx channel
// - Once we have that, check msb of command reg
// -> if 0 -> issue axi read transaction (assert ar_valid), go to state 3
// -> if 1 -> TBD (write transaction)
// 3 -> wait until partner asserts ar_ready, deassert ar_valid and assert r_ready, go to state 4
// 4 -> wait until partner asserts r_valid, deassert r_ready, transfer r_data to {uart_tx, uart_tx_next}, assert uart_tx_valid
//      go to state 5
// 5 wait for uart_tx_ready, then transfer uart_tx <= uart_tx_next and go to state 6
// 6 wait for uart_tx_ready, go to 0

endmodule
