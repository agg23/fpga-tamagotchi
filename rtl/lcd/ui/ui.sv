// For anyone looking at this, this method of creating UI is kind of a hack, and pieced together from other, more
// complete experiments of mine. I dislike all of this code, but it works for the purpose
module ui (
    input wire clk,

    input wire [9:0] video_fetch_x,
    input wire [9:0] video_fetch_y,

    // Settings
    input wire [2:0] turbo_speed,

    output wire active,
    output reg [23:0] vid_out
);
  localparam UI_SCALE = 2;
  localparam X_SCALE_BIT = UI_SCALE;
  localparam Y_SCALE_BIT = UI_SCALE;

  localparam UI_TEXT_WIDTH = (MAIN_TEXT_LENGTH + SPEED_TEXT_LENGTH) * UI_SCALE * 8;
  localparam UI_START_X = (360 - UI_TEXT_WIDTH) / 2;
  localparam UI_END_X = UI_START_X + UI_TEXT_WIDTH;

  localparam START_Y = 276;
  localparam TEXT_PADDING_Y = 10;

  localparam UI_START_Y = START_Y + TEXT_PADDING_Y;
  localparam UI_END_Y = UI_START_Y + 8 * UI_SCALE;
  localparam END_Y = START_Y + TEXT_PADDING_Y * 2 + 8 * UI_SCALE;

  // Comb
  reg [7:0] character = 0;

  localparam MAIN_TEXT_LENGTH = 13;
  localparam SPEED_TEXT_LENGTH = 3;
  reg [7:0] main_text[MAIN_TEXT_LENGTH] = '{
      "T",
      "u",
      "r",
      "b",
      "o",
      " ",
      "S",
      "p",
      "e",
      "e",
      "d",
      ":",
      " "
  };

  reg [7:0] speed_1x_text[3] = '{" ", "1", "x"};
  reg [7:0] speed_2x_text[3] = '{" ", "2", "x"};
  reg [7:0] speed_4x_text[3] = '{" ", "4", "x"};
  reg [7:0] speed_50x_text[3] = '{"5", "0", "x"};
  reg [7:0] speed_max_text[3] = '{"M", "a", "x"};

  always_comb begin
    reg [9:0] local_addr;
    character = 0;

    if (character_addr >= MAIN_TEXT_LENGTH) begin
      // Speed values
      local_addr = character_addr - MAIN_TEXT_LENGTH;
      if (local_addr[4:0] < 3) begin
        case (turbo_speed)
          0: character = speed_1x_text[local_addr[1:0]];
          1: character = speed_2x_text[local_addr[1:0]];
          2: character = speed_4x_text[local_addr[1:0]];
          3: character = speed_50x_text[local_addr[1:0]];
          // 4 and above default to max
          default: character = speed_max_text[local_addr[1:0]];
        endcase
      end
    end else if (character_addr < MAIN_TEXT_LENGTH) begin
      character = main_text[character_addr[3:0]];
    end
  end

  wire x_active = video_fetch_x >= UI_START_X && video_fetch_x < UI_END_X;
  wire y_active = video_fetch_y >= UI_START_Y && video_fetch_y < UI_END_Y;

  assign active = video_fetch_y >= START_Y && video_fetch_y < END_Y;

  wire [9:0] x_offset = video_fetch_x - UI_START_X;
  wire [9:0] y_offset = video_fetch_y - UI_START_Y;

  wire [3:0] char_x_pixel = video_fetch_x >= UI_START_X ? x_offset[3:0] : 0;
  wire [3:0] char_y_pixel = video_fetch_y >= UI_START_Y ? y_offset[3:0] : 0;

  wire [2:0] character_row = char_y_pixel[Y_SCALE_BIT+1:Y_SCALE_BIT-1];

  wire [9:0] x_offset_prefetch = x_offset + 1;
  wire [9:0] character_addr = {4'b0, x_offset_prefetch[9:4]};

  assign vid_out = x_active && y_active && font_line[7-char_x_pixel[X_SCALE_BIT+1:X_SCALE_BIT-1]] ? 24'hFFFFFF : 0;

  wire [7:0] font_line;

  char_rom char_rom (
      .clk(clk),

      .character(character - 32),
      .row(character_row),
      .data_out(font_line)
  );
endmodule
