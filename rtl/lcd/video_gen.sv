module video_gen #(
    parameter WIDTH = 10'd360,
    parameter HEIGHT = 10'd360,
    parameter LCD_PIXEL_SIZE = 5'd11,

    parameter VBLANK_LEN = 10'd132,
    parameter HBLANK_LEN = 10'd84,

    parameter VBLANK_OFFSET = 10'd5,
    parameter HBLANK_OFFSET = 10'd5,

    parameter LCD_X_OFFSET = 10'd0,
    parameter LCD_Y_OFFSET = 10'd0
) (
    input wire clk,

    output reg [7:0] video_addr = 0,

    output reg [9:0] x = 0,
    output reg [9:0] y = 0,

    output wire [1:0] lcd_segment_row,

    output reg  vsync = 0,
    output reg  hsync = 0,
    output wire de
);
  localparam VBLANK_TIME = HEIGHT + VBLANK_OFFSET;
  localparam HBLANK_TIME = WIDTH + HBLANK_OFFSET;

  localparam MAX_X = WIDTH + HBLANK_LEN;
  localparam MAX_Y = WIDTH + VBLANK_LEN;

  initial begin
    $display("VBLANK at: %d, HBLANK at: %d", VBLANK_TIME, HBLANK_TIME);
    $display("Max x, y: %d, %d", MAX_X, MAX_Y);
    $display("LCD Centering X: %d, Y: %d", LCD_X_OFFSET, LCD_Y_OFFSET);
  end

  reg [4:0] pixel_count_x = 0;
  reg [4:0] pixel_count_y = 0;

  // wire [9:0] lcd_x_base = x - 16;
  // wire [9:0] lcd_y_base = y - 104;
  // wire [4:0] lcd_x = lcd_x_base[9:5];
  // wire [4:0] lcd_y = lcd_y_base[9:5];
  reg [4:0] lcd_x = 0;
  reg [3:0] lcd_y = 0;

  assign lcd_segment_row = lcd_y[1:0];

  // reg [4:0] test_lcd_x = 0  /* synthesis noprune */;
  // reg [4:0] test_lcd_y = 0  /* synthesis noprune */;

  assign de = x < WIDTH && y < HEIGHT;

  function [5:0] lcd_column_addr(reg [5:0] x_coord);
    // const reverse_map = [
    //       0, 1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 12, 13, 14, 15, 16, 36, 35, 34, 33,
    //       32, 31, 30, 29, 27, 26, 25, 24, 23, 22, 21, 20, 8, 17, 18, 19, 28, 37,
    //       38, 39,
    //     ];
    case (x_coord)
      0:  return 0;
      1:  return 1;
      2:  return 2;
      3:  return 3;
      4:  return 4;
      5:  return 5;
      6:  return 6;
      7:  return 7;
      8:  return 9;
      9:  return 10;
      10: return 11;
      11: return 12;
      12: return 13;
      13: return 14;
      14: return 15;
      15: return 16;
      16: return 36;
      17: return 35;
      18: return 34;
      19: return 33;
      20: return 32;
      21: return 31;
      22: return 30;
      23: return 29;
      24: return 27;
      25: return 26;
      26: return 25;
      27: return 24;
      28: return 23;
      29: return 22;
      30: return 21;
      31: return 20;
      32: return 8;
      33: return 17;
      34: return 18;
      35: return 19;
      36: return 28;
      37: return 37;
      38: return 38;
      39: return 39;
    endcase
  endfunction

  always @(posedge clk) begin
    reg [9:0] next_x;
    reg [9:0] next_y;
    reg [4:0] next_lcd_x;
    reg [3:0] next_lcd_y;
    reg [7:0] temp_video_addr;

    hsync <= 0;
    vsync <= 0;

    next_x = x + 10'b1;
    next_y = y;

    if (next_y == VBLANK_TIME && next_x == WIDTH + 10'b1) begin
      // VSync
      vsync <= 1;
      lcd_y <= 0;
      pixel_count_y <= 0;
    end else if (next_x == HBLANK_TIME) begin
      // HSync
      hsync <= 1;
      lcd_x <= 0;
      pixel_count_x <= 0;
    end else if (next_x == MAX_X) begin
      next_x = 10'h0;
      next_y = y + 10'b1;

      if (next_y == MAX_Y) begin
        next_y = 10'h0;
      end
    end

    x <= next_x;
    y <= next_y;
    next_lcd_x = lcd_x;
    next_lcd_y = lcd_y;
    // test_lcd_x <= next_lcd_x;
    // test_lcd_y <= next_lcd_y;

    if (next_x >= LCD_X_OFFSET && next_x < WIDTH - LCD_X_OFFSET && next_y >= LCD_Y_OFFSET && next_y < HEIGHT - LCD_Y_OFFSET) begin
      pixel_count_x <= pixel_count_x + 5'b1;

      if (pixel_count_x == LCD_PIXEL_SIZE - 5'b1) begin
        // End of this pixel horizontally
        pixel_count_x <= 0;

        next_lcd_x = lcd_x + 5'b1;

        if (lcd_x == 5'd31) begin
          // End of row
          next_lcd_x = 0;

          pixel_count_y <= pixel_count_y + 5'b1;

          if (pixel_count_y == LCD_PIXEL_SIZE - 5'b1) begin
            // End of this pixel vertically
            pixel_count_y <= 0;

            next_lcd_y = lcd_y + 4'b1;

            if (lcd_y == 4'd15) begin
              // End of column
              next_lcd_y = 0;
            end
          end
        end
      end

      lcd_x <= next_lcd_x;
      lcd_y <= next_lcd_y;
    end

    // Upper bits are column address, lowest bit is whether it's Y=0 or Y=4
    temp_video_addr = {1'b0, lcd_column_addr({1'b0, next_lcd_x[4:0]}), next_lcd_y[2]};

    // If Y >= 8, it's in second RAM bank
    if (next_lcd_y >= 8) begin
      temp_video_addr = temp_video_addr + 8'h50;
    end

    video_addr <= temp_video_addr;
  end

endmodule
