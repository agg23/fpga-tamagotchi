module video #(
    parameter WIDTH = 10'd360,
    parameter HEIGHT = 10'd360,
    parameter LCD_PIXEL_SIZE = 5'd11,

    parameter VBLANK_LEN = 10'd132,
    parameter HBLANK_LEN = 10'd84,

    parameter VBLANK_OFFSET = 10'd5,
    parameter HBLANK_OFFSET = 10'd5
) (
    input wire clk,

    output wire [7:0] video_addr,
    input  wire [3:0] video_data,

    input wire background_write_en,
    input wire spritesheet_write_en,
    input wire [16:0] image_write_addr,
    input wire [15:0] image_write_data,

    // Settings
    input wire show_pixel_dividers,
    input wire show_pixel_grid_background,

    output wire vsync,
    output wire hsync,
    output wire de,
    output wire [23:0] rgb
);
  localparam LCD_X_OFFSET = (WIDTH - 32 * LCD_PIXEL_SIZE) / 2;
  localparam LCD_Y_OFFSET = (HEIGHT - 16 * LCD_PIXEL_SIZE) / 2;

  localparam HORIZONTAL_TOTAL = WIDTH + HBLANK_LEN;

  wire [15:0] background_pixel_rgb565;
  wire [23:0] background_pixel_rgb888;

  wire [9:0] video_x;
  wire [9:0] video_y;
  wire [1:0] lcd_segment_row;

  wire [31:0] lcd_pixel;

  wire active_sprite_pixel;
  wire [7:0] sprite_alpha_pixel;

  wire [23:0] background_pixel_with_lcd;

  wire [7:0] sprite_enable_status;

  rgb565_to_rgb888 background_color_conversion (
      .rgb565(background_pixel_rgb565),
      .rgb888(background_pixel_rgb888)
  );

  alpha_blend lcd_alpha_blend (
      .background_pixel(background_pixel_rgb888),
      .foreground_pixel(lcd_pixel),
      .output_pixel(background_pixel_with_lcd)
  );

  alpha_blend sprite_alpha_blend (
      .background_pixel(background_pixel_with_lcd),
      .foreground_pixel(active_sprite_pixel ? {24'b0, sprite_alpha_pixel} : 0),
      .output_pixel(rgb)
  );

  wire [9:0] video_fetch_x = video_x == HORIZONTAL_TOTAL - 1 ? 0 : video_x + 10'h1;
  wire [9:0] video_fetch_y = video_x == HORIZONTAL_TOTAL - 1 ? video_y > HEIGHT ? 0 : video_y + 10'h1 : video_y;

  sprites #(
      .WIDTH(WIDTH)
  ) sprites (
      .clk(clk),

      .video_x(video_fetch_x),
      .video_y(video_fetch_y),

      .sprite_enable_status(sprite_enable_status),

      .image_write_en  (spritesheet_write_en),
      .image_write_addr(image_write_addr[14:0]),
      .image_write_data(image_write_data[7:0]),

      .active_pixel(active_sprite_pixel),
      .pixel_alpha (sprite_alpha_pixel)
  );

  image_memory #(
      .MEM_WIDTH(360),
      .MEM_HEIGHT(360),
      .SPRITE_WIDTH(360),
      .SPRITE_HEIGHT(360),
      // No alpha needed
      .PIXEL_BIT_COUNT(16)
  ) background (
      .clk(clk),

      .sprite(0),
      .x(video_fetch_x),
      .y(video_fetch_y),

      .image_write_en  (background_write_en),
      .image_write_addr(image_write_addr),
      .image_write_data(image_write_data),

      .pixel(background_pixel_rgb565)
  );

  wire [4:0] lcd_subpixel_x;
  wire [4:0] lcd_subpixel_y;

  wire [7:0] lcd_video_addr;
  wire [3:0] lcd_video_data;

  lcd #(
      .WIDTH(WIDTH),
      .HEIGHT(HEIGHT),
      .LCD_X_OFFSET(LCD_X_OFFSET),
      .LCD_Y_OFFSET(LCD_Y_OFFSET)
  ) lcd (
      .video_x(video_fetch_x),
      .video_y(video_fetch_y),

      .lcd_subpixel_x(lcd_subpixel_x),
      .lcd_subpixel_y(lcd_subpixel_y),

      .lcd_segment_row(lcd_segment_row),
      .video_data(lcd_video_data),

      // Settings
      .show_pixel_dividers(show_pixel_dividers),
      .show_pixel_grid_background(show_pixel_grid_background),

      .pixel(lcd_pixel)
  );

  frame_ram frame_ram (
      .clk(clk),

      .frame_addr(lcd_video_addr),
      .frame_data(lcd_video_data),

      .sprite_enable_status(sprite_enable_status),

      .cpu_video_addr(video_addr),
      .cpu_video_data(video_data),

      .vsync(vsync)
  );

  video_gen #(
      .WIDTH(WIDTH),
      .HEIGHT(HEIGHT),
      .LCD_PIXEL_SIZE(LCD_PIXEL_SIZE),

      .VBLANK_LEN(VBLANK_LEN),
      .HBLANK_LEN(HBLANK_LEN),

      .LCD_X_OFFSET(LCD_X_OFFSET),
      .LCD_Y_OFFSET(LCD_Y_OFFSET)
  ) video_gen (
      .clk(clk),

      .video_addr(lcd_video_addr),

      .x(video_x),
      .y(video_y),

      .lcd_subpixel_x(lcd_subpixel_x),
      .lcd_subpixel_y(lcd_subpixel_y),

      .lcd_segment_row(lcd_segment_row),

      .vsync(vsync),
      .hsync(hsync),
      .de(de)
  );

endmodule
