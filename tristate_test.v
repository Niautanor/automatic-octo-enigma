`include "output_pin_with_enable.v"

module tristate_test(input clk, output out);

localparam COUNT = 10000;
localparam WIDTH = $clog2(COUNT-1);

reg [WIDTH-1:0] div = 0;
reg [1:0] state = 0;

wire data = state[1];
wire enable = !state[0];

// 0 z(0) 1 z(1)

always @(posedge clk) begin
    div <= div + 1;
    if (div == COUNT - 1) begin
        div <= 0;
        state <= state + 1;
    end
end

output_pin_with_enable p(.data(data), .enable(enable), .pin(out));

endmodule
