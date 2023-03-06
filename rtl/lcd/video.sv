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
  localparam LCD_X_OFFSET = (WIDTH - 32 * PIXEL_SIZE) / 2;
  localparam LCD_Y_OFFSET = (HEIGHT - 16 * PIXEL_SIZE) / 2;

  wire [23:0] lcd_pixel;
  wire [31:0] base_pixel;

  wire [9:0] video_x;
  wire [9:0] video_y;
  wire [1:0] lcd_segment_row;

  wire lcd_active;
  wire active_sprite_pixel;
  wire [31:0] sprite_pixel;

  wire [23:0] background_pixel_with_lcd = lcd_active ? 24'h0A0A0A : base_pixel[31:8];

  alpha_blend alpha_blend (
      .background_pixel(background_pixel_with_lcd),
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

  image_memory #(
      .MEM_WIDTH(720),
      .MEM_HEIGHT(720),
      .SPRITE_WIDTH(720),
      .SPRITE_HEIGHT(720)
  ) background (
      .clk(clk),

      .sprite(0),
      .x(video_x),
      .y(video_y),

      // TODO
      .pixel_write_en  (0),
      .pixel_write_addr(0),
      .pixel_write_data(0),

      .pixel(base_pixel)
  );

  lcd #(
      .WIDTH(WIDTH),
      .HEIGHT(HEIGHT),
      .LCD_X_OFFSET(LCD_X_OFFSET),
      .LCD_Y_OFFSET(LCD_Y_OFFSET)
  ) lcd (
      .clk(clk),

      .video_x(video_x),
      .video_y(video_y),
      .lcd_segment_row(lcd_segment_row),

      .video_data(video_data),

      .lcd_active(lcd_active)
  );

  video_gen #(
      .WIDTH(WIDTH),
      .HEIGHT(HEIGHT),
      .PIXEL_SIZE(PIXEL_SIZE),

      .VBLANK_LEN(VBLANK_LEN),
      .HBLANK_LEN(HBLANK_LEN),

      .LCD_X_OFFSET(LCD_X_OFFSET),
      .LCD_Y_OFFSET(LCD_Y_OFFSET)
  ) video_gen (
      .clk(clk),

      .video_addr(video_addr),

      .x(video_x),
      .y(video_y),

      .lcd_segment_row(lcd_segment_row),

      .vsync(vsync),
      .hsync(hsync),
      .de(de)
  );

endmodule
