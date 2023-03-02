module top (
    input wire clk,

    input wire reset_n,

    output wire vsync,
    output wire hsync,
    output wire de,
    output wire [23:0] rgb
);

  reg [15:0] rom[8192];

  initial $readmemh("../../../bass/tama.hex", rom);

  wire [12:0] rom_addr;
  reg [11:0] rom_data = 0;

  wire [7:0] video_addr;
  wire [3:0] video_data;

  reg clk_en_32_768khz = 0;

  reg clock_div = 1;

  // Clock divider that uses both edges of the clock to align the divided clock
  always @(negedge clk) begin
    clock_div <= ~clock_div;
  end

  always @(posedge clk) begin
    clk_en_32_768khz <= clock_div;
  end

  cpu_6s46 tamagotchi (
      .clk(clk),
      .clk_en(clk_en_32_768khz),
      .clk_2x_en(clk),
      .clk_vid(clk),

      .reset_n(reset_n),

      .input_k0(4'h7),
      .input_k1(4'h0),

      .rom_addr(rom_addr),
      .rom_data(rom_data),

      .video_addr(video_addr),
      .video_data(video_data)
  );

  video #(
      .WIDTH(240),
      .HEIGHT(240),
      .PIXEL_SIZE(7),

      .VBLANK_LEN(16),
      .HBLANK_LEN(16)
  ) video (
      .clk(clk),

      .video_addr(video_addr),
      .video_data(video_data),

      .vsync(vsync),
      .hsync(hsync),
      .de(de),
      .rgb(rgb)
  );

  always @(posedge clk) begin
    // ROM access
    rom_data <= rom[rom_addr][11:0];
  end

endmodule
