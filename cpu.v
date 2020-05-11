`include "uart_tx.v"

module cpu(input clk, output tx);

reg [7:0] memory [256];
initial $readmemh("cpu.hex", memory);

reg [7:0] pc = 0;
reg [7:0] instruction = 0;
reg [7:0] data;

reg uart_en = 0;
wire uart_rdy;

reg phase = 0;

uart_tx uart(.clk(clk), .rst(1'b0), .en(uart_en), .data_in(data), .rdy(uart_rdy), .tx(tx));

always @(posedge clk) begin
    uart_en <= 0;
    phase <= ~phase;
    if (phase == 0) begin
        instruction <= memory[pc];
        pc <= pc + 1;
    end else begin
        case (instruction)
        0: begin // nop
        end
        1: begin // jump
            pc <= memory[pc];
        end
        2: begin // load data
            data <= memory[pc];
            pc <= pc+1;
        end
        3: begin // out
            uart_en <= 1;
        end
        4: begin // wait for uart
            if (!uart_rdy) pc <= pc - 1;
        end
        5: begin // halt
            pc <= pc - 1;
        end
        endcase
    end
end

endmodule
