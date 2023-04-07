module top (
    input  wire clk,
    output wire clk_65_536khz,

    input wire reset_n,

    input wire left_button,
    input wire middle_button,
    input wire right_button,

    output wire vsync,
    output wire hsync,
    output wire de,
    output wire [23:0] rgb
);

  reg [15:0] rom[8192];

  initial begin
    $readmemh("../../../bass/tama.hex", rom);
    $readmemh("../../../assets/bin/spritesheet.hex", video.sprites.sprite_mem.memory);
    $readmemh("../../../assets/bin/background.hex", video.background.memory);
  end

  wire [12:0] rom_addr;
  reg [11:0] rom_data = 0;

  wire [7:0] video_addr;
  wire [3:0] video_data;

  reg clk_en_32_768khz = 0;
  reg clk_en_65_536khz = 0;

  reg [9:0] clock_div = 10'd100;

  // Clock divider
  always @(posedge clk) begin
    clk_en_32_768khz <= 0;
    clk_en_65_536khz <= 0;

    clock_div <= clock_div - 10'h1;

    if (clock_div == 0) begin
      clock_div <= 10'd100;

      clk_en_32_768khz <= 1;
      clk_en_65_536khz <= 1;
    end else if (clock_div == 50) begin
      clk_en_65_536khz <= 1;
    end
  end

  assign clk_65_536khz = clk_en_65_536khz;

  wire buzzer;

  wire lcd_all_off_setting;
  wire lcd_all_on_setting;

  reg ss_bus_reset = 1;

  wire [31:0] ss_bus_out;
  wire ss_ready;

  always @(posedge clk) begin
    if (clk_en_32_768khz) begin
      ss_bus_reset <= 0;
    end
  end

  cpu_6s46 #(
      .SIM_TYPE("verilator")
  ) tamagotchi (
      .clk(clk),
      .clk_en(clk_en_32_768khz),
      .clk_2x_en(clk_en_65_536khz),

      .reset(~reset_n),

      // Left, middle, right
      .input_k0({1'b0, ~left_button, ~middle_button, ~right_button}),
      .input_k1(4'h0),

      .rom_addr(rom_addr),
      .rom_data(rom_data),

      .video_addr(video_addr),
      .video_data(video_data),

      .buzzer(buzzer),

      // Settings
      .lcd_all_off_setting(lcd_all_off_setting),
      .lcd_all_on_setting (lcd_all_on_setting),

      // Savestates
      .ss_bus_in(0),
      .ss_bus_addr(0),
      .ss_bus_wren(0),
      .ss_bus_reset(ss_bus_reset),
      .ss_bus_out(ss_bus_out),

      .ss_ready(ss_ready)
  );

  video video (
      .clk(clk),

      .video_addr(video_addr),
      .video_data(video_data),

      .background_write_en(0),
      .spritesheet_write_en(0),
      .image_write_addr(0),
      .image_write_data(0),

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
