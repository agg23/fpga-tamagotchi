module sprites (
    input wire clk,

    input wire [9:0] video_x,
    input wire [9:0] video_y,

    input wire pixel_write_en,
    input wire [16:0] pixel_write_addr,
    input wire [31:0] pixel_write_data,

    output wire active_pixel,
    output wire [31:0] pixel
);
  localparam SCREEN_WIDTH = 10'd720;
  localparam SPRITE_WIDTH = 10'd100;
  localparam SPRITE_SPACING = 10'd50;

  localparam INITIAL_X_SPACING = (SCREEN_WIDTH - ((SPRITE_WIDTH + SPRITE_SPACING) * 4 - SPRITE_SPACING)) / 2;
  localparam INITIAL_Y_SPACING = 10'd55;

  localparam x_0 = INITIAL_X_SPACING;
  localparam x_1 = x_0 + SPRITE_WIDTH + SPRITE_SPACING;
  localparam x_2 = x_1 + SPRITE_WIDTH + SPRITE_SPACING;
  localparam x_3 = x_2 + SPRITE_WIDTH + SPRITE_SPACING;

  localparam y_0 = INITIAL_Y_SPACING;
  localparam y_1 = SCREEN_WIDTH - SPRITE_WIDTH - INITIAL_Y_SPACING;
  // ------------------

  wire sprite_0_x = video_x >= x_0 && video_x < x_0 + SPRITE_WIDTH;
  wire sprite_1_x = video_x >= x_1 && video_x < x_1 + SPRITE_WIDTH;
  wire sprite_2_x = video_x >= x_2 && video_x < x_2 + SPRITE_WIDTH;
  wire sprite_3_x = video_x >= x_3 && video_x < x_3 + SPRITE_WIDTH;

  wire sprite_top_y = video_y >= y_0 && video_y < y_0 + SPRITE_WIDTH;
  wire sprite_bottom_y = video_y >= y_1 && video_y < y_1 + SPRITE_WIDTH;

  wire active_sprite = (sprite_top_y || sprite_bottom_y) && (sprite_0_x || sprite_1_x || sprite_2_x || sprite_3_x);
  assign active_pixel = active_sprite && pixel != 0;

  // Comb
  reg [2:0] sprite;
  reg [6:0] sprite_x;
  reg [6:0] sprite_y;

  always_comb begin
    reg [2:0] selected_sprite;
    reg [9:0] sub_result_x;
    reg [9:0] sub_result_y;

    selected_sprite = 0;
    sub_result_x = 0;
    sub_result_y = 0;

    if (sprite_0_x) begin
      sub_result_x = video_x - x_0;
      selected_sprite = 0;
    end else if (sprite_1_x) begin
      sub_result_x = video_x - x_1;
      selected_sprite = 1;
    end else if (sprite_2_x) begin
      sub_result_x = video_x - x_2;
      selected_sprite = 2;
    end else if (sprite_3_x) begin
      sub_result_x = video_x - x_3;
      selected_sprite = 3;
    end

    if (sprite_top_y) begin
      sub_result_y = video_y - y_0;
      selected_sprite[2] = 0;
    end else if (sprite_bottom_y) begin
      sub_result_y = video_y - y_1;
      selected_sprite[2] = 1;
    end

    sprite   = selected_sprite;
    sprite_x = sub_result_x[6:0];
    sprite_y = sub_result_y[6:0];
  end

  image_memory #(
      .MEM_WIDTH(800),
      .MEM_HEIGHT(100),
      .SPRITE_WIDTH(100),
      .SPRITE_HEIGHT(100)
  ) sprite_mem (
      .clk(clk),

      .pixel_write_en  (pixel_write_en),
      .pixel_write_addr(pixel_write_addr),
      .pixel_write_data(pixel_write_data),

      .sprite(sprite),
      .x(sprite_x),
      .y(sprite_y),

      .pixel(pixel)
  );

endmodule
