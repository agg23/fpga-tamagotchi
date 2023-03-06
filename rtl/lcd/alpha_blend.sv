module alpha_blend (
    input [23:0] background_pixel,
    input [31:0] forground_pixel,

    output [23:0] output_pixel
);

  wire [ 7:0] alpha = forground_pixel[7:0];
  wire [ 7:0] inverted_alpha = 8'hFF - alpha;

  wire [15:0] color_r = forground_pixel[31:24] * alpha + background_pixel[23:16] * inverted_alpha;
  wire [15:0] color_g = forground_pixel[23:16] * alpha + background_pixel[15:8] * inverted_alpha;
  wire [15:0] color_b = forground_pixel[15:8] * alpha + background_pixel[7:0] * inverted_alpha;

  assign output_pixel = {color_r[15:8], color_g[15:8], color_b[15:8]};

endmodule
