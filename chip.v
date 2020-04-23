/******************************************************************************
*                                                                             *
* Copyright 2016 myStorm Copyright and related                                *
* rights are licensed under the Solderpad Hardware License, Version 0.51      *
* (the “License”); you may not use this file except in compliance with        *
* the License. You may obtain a copy of the License at                        *
* http://solderpad.org/licenses/SHL-0.51. Unless required by applicable       *
* law or agreed to in writing, software, hardware and materials               *
* distributed under this License is distributed on an “AS IS” BASIS,          *
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or             *
* implied. See the License for the specific language governing                *
* permissions and limitations under the License.                              *
*                                                                             *
******************************************************************************/
module chip (
    // 100MHz clock input
    input  clk,
    // UART
    output UART_TX
  );

  wire _reset = 0;

  reg [7:0] next_data = 8'h41;
  reg en = 0;
  wire rdy;

  always @(posedge clk) begin
    if (rdy) begin
      en <= 1;
    end else begin
      if (en) begin
        if (next_data == 8'h57)
          next_data <= 8'h41;
        else
          next_data <= next_data + 1;
      end
      en <= 0;
    end
  end

  uart_tx uart(
      .clk(clk),
      .rst(_reset),
      .en(en),
      .data_in(next_data),
      .rdy(rdy),
      .tx(UART_TX)
  );

endmodule
