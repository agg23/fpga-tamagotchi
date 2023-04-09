module lcd #(
    parameter WIDTH  = 10'd720,
    parameter HEIGHT = 10'd720,

    parameter LCD_X_OFFSET = 10'd0,
    parameter LCD_Y_OFFSET = 10'd0
) (
    input wire clk,

    input wire [9:0] video_x,
    input wire [9:0] video_y,

    input wire [5:0] lcd_subpixel_x,
    input wire [4:0] lcd_subpixel_y,

    input wire [1:0] lcd_segment_row,
    input wire [3:0] video_data,

    // Settings
    input wire show_pixel_dividers,
    input wire show_pixel_grid_background,

    // Comb
    output wire [31:0] pixel
);
  // Comb
  reg lcd_active;

  // Buffered Settings
  reg show_pixel_dividers_buf;
  reg show_pixel_grid_background_buf;

  wire render_grid_divider = show_pixel_dividers_buf && (lcd_subpixel_x == 0 || lcd_subpixel_y == 0);

  wire [31:0] lcd_background_color = show_pixel_grid_background_buf ? 32'h0A0A0A_1F : 0;

  // Color of current pixel when on/off, including alpha
  wire [31:0] lcd_on_off_pixel = lcd_active ? 32'h0A0A0A_FF : lcd_background_color;

  // LCD pixel including grid and actual LCD on/off states
  assign pixel = render_grid_divider ? 32'h000000_00 : lcd_on_off_pixel;

  always_comb begin
    lcd_active = 0;

    if (video_x >= LCD_X_OFFSET && video_x < WIDTH - LCD_X_OFFSET && video_y >= LCD_Y_OFFSET && video_y < HEIGHT - LCD_Y_OFFSET) begin
      // Horizontal and vertical range of main LCD
      lcd_active = video_data[lcd_segment_row];
    end
  end

  always @(posedge clk) begin
    // Buffer settings to prevent a long comb chain from the settings synch all the way to the video DDIO
    show_pixel_dividers_buf <= show_pixel_dividers;
    show_pixel_grid_background_buf <= show_pixel_grid_background;
  end

endmodule
