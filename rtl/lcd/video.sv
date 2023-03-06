module video #(
    parameter WIDTH = 10'd720,
    parameter HEIGHT = 10'd720,
    parameter PIXEL_SIZE = 5'd22,

    parameter VBLANK_LEN = 10'd19,
    parameter HBLANK_LEN = 10'd19,

    parameter VBLANK_OFFSET = 10'd5,
    parameter HBLANK_OFFSET = 10'd5
) (
    input wire clk,

    output reg  [7:0] video_addr = 0,
    input  wire [3:0] video_data,

    output reg vsync = 0,
    output reg hsync = 0,
    output wire de,
    output wire [23:0] rgb
);
  wire [23:0] base_pixel;

  wire [9:0] video_x;
  wire [9:0] video_y;

  wire active_sprite_pixel;
  wire [31:0] sprite_pixel;

  alpha_blend alpha_blend (
      .background_pixel(base_pixel),
      .forground_pixel(active_sprite_pixel ? sprite_pixel : 0),
      .output_pixel(rgb)
  );

  sprites sprites (
      .clk(clk),

      .video_x(video_x),
      .video_y(video_y),

      // TODO
      .pixel_write_en  (0),
      .pixel_write_addr(0),
      .pixel_write_data(0),

      .active_pixel(active_sprite_pixel),
      .pixel(sprite_pixel)
  );

  video_gen #(
      .WIDTH(WIDTH),
      .HEIGHT(HEIGHT),
      .PIXEL_SIZE(PIXEL_SIZE),

      .VBLANK_LEN(VBLANK_LEN),
      .HBLANK_LEN(HBLANK_LEN)
  ) video_gen (
      .clk(clk),

      .video_addr(video_addr),
      .video_data(video_data),

      .x(video_x),
      .y(video_y),

      .vsync(vsync),
      .hsync(hsync),
      .de(de),
      .rgb(base_pixel)
  );

endmodule
