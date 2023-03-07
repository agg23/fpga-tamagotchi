// Supports horizontal sprite sheets (or single images) only
module image_memory #(
    parameter MEM_WIDTH = 100,
    parameter MEM_HEIGHT = 100,
    parameter SPRITE_WIDTH = 100,
    parameter SPRITE_HEIGHT = 100,
    parameter PIXEL_BIT_COUNT = 32
) (
    input wire clk,

    input wire [SPRITE_ADDR_SIZE_WITH_NEG_ONE:0] sprite,
    input wire [SPRITE_X_SIZE - 1:0] x,
    input wire [SPRITE_Y_SIZE - 1:0] y,

    input wire image_write_en,
    input wire [ADDR_SIZE-1:0] image_write_addr,
    input wire [PIXEL_BIT_COUNT-1:0] image_write_data,

    output reg [PIXEL_BIT_COUNT -1:0] pixel = 0
);

  localparam MEM_SIZE = MEM_WIDTH * MEM_HEIGHT;
  localparam SPRITE_SIZE = SPRITE_WIDTH * SPRITE_HEIGHT;
  localparam SPRITE_COUNT = MEM_SIZE / SPRITE_SIZE;

  localparam ADDR_SIZE = $clog2(MEM_SIZE);
  localparam SPRITE_X_SIZE = $clog2(SPRITE_WIDTH);
  localparam SPRITE_Y_SIZE = $clog2(SPRITE_HEIGHT);
  localparam SPRITE_ADDR_SIZE_WITH_NEG_ONE = $clog2(
      SPRITE_COUNT
  ) == 0 ? 0 : $clog2(
      SPRITE_COUNT
  ) - 1;

  // --------------------------------------------

  reg [PIXEL_BIT_COUNT-1:0] memory[MEM_SIZE];

  wire [ADDR_SIZE -1:0] sprite_y_base_addr = (y * MEM_WIDTH) + (sprite * SPRITE_WIDTH);
  // TODO: Is there a better way to write this?
  wire [ADDR_SIZE - 1:0] sprite_addr = sprite_y_base_addr + {{ADDR_SIZE - SPRITE_X_SIZE{1'b0}}, x};

  always @(posedge clk) begin
    if (image_write_en) begin
      memory[image_write_addr] <= image_write_data;
    end else begin
      pixel <= memory[sprite_addr];
    end
  end

endmodule
