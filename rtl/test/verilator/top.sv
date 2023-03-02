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
  reg clk_en_65_536khz = 0;

  reg [9:0] clock_div = 10'd1000;

  // Clock divider
  always @(posedge clk) begin
    clk_en_32_768khz <= 0;
    clk_en_65_536khz <= 0;

    clock_div <= clock_div - 10'h1;

    if (clock_div == 0) begin
      clock_div <= 10'd1000;

      clk_en_32_768khz <= 1;
      clk_en_65_536khz <= 1;
    end else if (clock_div == 500) begin
      clk_en_65_536khz <= 1;
    end
  end

  cpu_6s46 tamagotchi (
      .clk(clk),
      .clk_en(clk_en_32_768khz),
      .clk_2x_en(clk_en_65_536khz),
      .clk_vid(clk),

      .reset_n(reset_n),

      .input_k0(4'h7),
      .input_k1(4'h0),

      .rom_addr(rom_addr),
      .rom_data(rom_data),

      .video_addr(video_addr),
      .video_data(video_data)
  );

  video video (
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
