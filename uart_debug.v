`ifndef UART_DEBUG
`define UART_DEBUG

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
    input [15:0] axi_r_data, input axi_r_valid, output reg axi_r_ready,
    // axi write address channel
    output reg [17:0] axi_aw_addr, output reg axi_aw_valid, input axi_aw_ready,
    // axi write data channel
    output reg [15:0] axi_w_data, output reg axi_w_valid, input axi_w_ready,
    // axi write response channel
    input axi_b_valid, output reg axi_b_ready,
    // debug stuff
    output [2:0] leds
);

initial uart_rx_ready = 1;
initial uart_tx_valid = 0;

initial axi_ar_valid = 0;
initial axi_ar_addr = 0;
initial axi_r_ready = 0;

initial axi_aw_valid = 0;
initial axi_ar_addr = 0;
initial axi_w_valid = 0;
initial axi_w_data = 0;
initial axi_b_ready = 0;

reg [23:8] command_reg = 0;
reg [15:8] wr_data_reg = 0;
reg [7:0] uart_tx_next = 0;
initial uart_tx = 0;

integer state = 0;
assign leds = state[2:0];
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
            if (command_reg[23]) begin
                axi_aw_valid <= 1;
                axi_aw_addr <= {command_reg[17:8], uart_rx};
                state <= 7;
            end else begin
                uart_rx_ready <= 0;
                axi_ar_valid <= 1;
                axi_ar_addr <= {command_reg[17:8], uart_rx};
                state <= 3;
            end
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
        7: if (uart_rx_valid) begin
            wr_data_reg[15:8] <= uart_rx;
            state <= 8;
        end
        8: if (uart_rx_valid) begin
            uart_rx_ready <= 0;
            axi_w_valid <= 1;
            axi_w_data <= {wr_data_reg[15:8], uart_rx};
            state <= 9;
        end
        9: begin
            if (axi_aw_ready) axi_aw_valid <= 0;
            if (axi_w_ready) axi_w_valid <= 0;
            if ((axi_aw_ready | !axi_aw_valid) & (axi_w_ready | !axi_w_valid)) begin
                axi_b_ready <= 1;
                state <= 10;
            end
        end
        10: if (axi_b_valid) begin
            axi_b_ready <= 0;
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
// -> if 1 -> issue axi write address, go to 7
// 3 -> wait until partner asserts ar_ready, deassert ar_valid and assert r_ready, go to state 4
// 4 -> wait until partner asserts r_valid, deassert r_ready, transfer r_data to {uart_tx, uart_tx_next}, assert uart_tx_valid
//      go to state 5
// 5 wait for uart_tx_ready, then transfer uart_tx <= uart_tx_next and go to state 6
// 6 wait for uart_tx_ready, go to 0
// 7 wait for upper byte of data register then go to 8
// 8 wait for lower byte of data register, issue axi_w transaction then go to 9
// 9 wait for both write address and write data to be accepted by axi partner then set b_ready and go to 10
// 10 wait for axi partner to set b_valid then go back to idle

endmodule

`endif
