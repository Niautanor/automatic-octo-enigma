module output_pin_with_enable(input data, input enable, output pin);

SB_IO #(
    .PIN_TYPE(6'b 1010_01),
    .PULLUP(1'b 0)
) sb_io (
    .PACKAGE_PIN(pin),
    .OUTPUT_ENABLE(enable),
    .D_OUT_0(data),
);

endmodule
