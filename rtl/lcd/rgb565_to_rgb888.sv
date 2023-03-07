module rgb565_to_rgb888 (
    input  wire [15:0] rgb565,
    output wire [23:0] rgb888
);

  // Constants taken from https://stackoverflow.com/a/9069480
  wire [13:0] red = {2'b0, rgb565[15:11]} * 10'd527 + 14'd23;
  wire [13:0] green = {1'b0, rgb565[10:5]} * 10'd259 + 14'd33;
  wire [13:0] blue = {2'b0, rgb565[4:0]} * 10'd527 + 14'd23;

  assign rgb888[23:16] = red[13:6];
  assign rgb888[15:8]  = green[13:6];
  assign rgb888[7:0]   = blue[13:6];

endmodule
