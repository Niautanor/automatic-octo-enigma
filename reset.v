module reset(input clk, output rst);

reg [27:0] cnt = 0;

assign rst = (cnt == 100000000);

always @(posedge clk) begin
    if (rst) begin
        cnt <= 0;
    end else begin
        cnt <= cnt + 1;
    end
end

endmodule
