module lcd #(
    parameter WIDTH  = 10'd720,
    parameter HEIGHT = 10'd720,

    parameter LCD_X_OFFSET = 10'd0,
    parameter LCD_Y_OFFSET = 10'd0
) (
    input wire clk,

    input wire [9:0] video_x,
    input wire [9:0] video_y,

    input wire [1:0] lcd_segment_row,
    input wire [3:0] video_data,

    output reg lcd_active
);

  always @(posedge clk) begin
    lcd_active <= 0;

    if (video_x >= LCD_X_OFFSET && video_x < WIDTH - LCD_X_OFFSET && video_y >= LCD_Y_OFFSET && video_y < HEIGHT - LCD_Y_OFFSET) begin
      // Horizontal and vertical range of main LCD
      lcd_active <= video_data[lcd_segment_row];
    end
  end

endmodule
