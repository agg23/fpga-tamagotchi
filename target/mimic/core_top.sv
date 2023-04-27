//------------------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2022, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// Copyright (c) 2022 OpenGateware authors and contributors
// Copyright (c) 2017 Alexey Melnikov <pour.garbage@gmail.com>
// Copyright (c) 2015 Till Harbaum <till@harbaum.org>
//
// This source file is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.
//
//------------------------------------------------------------------------------
//
// Platform Specific top-level
// Instantiated by the real top-level: sys_top
//
//------------------------------------------------------------------------------

module core_top (
    //Master input clock
    input CLK_50M,

    //Async reset from top-level module.
    //Can be used as initial reset.
    input RESET,

    //Must be passed to hps_io module
    inout [48:0] HPS_BUS,

    //Base video clock. Usually equals to CLK_SYS.
    output CLK_VIDEO,

    //Multiple resolutions are supported using different CE_PIXEL rates.
    //Must be based on CLK_VIDEO
    output CE_PIXEL,

    //Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
    //if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
    output [12:0] VIDEO_ARX,
    output [12:0] VIDEO_ARY,

    output [7:0] VGA_R,
    output [7:0] VGA_G,
    output [7:0] VGA_B,
    output       VGA_HS,
    output       VGA_VS,
    output       VGA_DE,      // = ~(vblank | hblank)
    output       VGA_F1,
    output [1:0] VGA_SL,
    output       VGA_SCALER,  // Force VGA scaler
    output       VGA_DISABLE, // analog out is off

    input  [11:0] HDMI_WIDTH,
    input  [11:0] HDMI_HEIGHT,
    output        HDMI_FREEZE,

`ifdef NSX_ENABLE_FB
    // Use framebuffer in DDRAM
    // FB_FORMAT:
    //    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
    //    [3]   : 0=16bits 565 1=16bits 1555
    //    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
    //
    // FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
    output        FB_EN,
    output [ 4:0] FB_FORMAT,
    output [11:0] FB_WIDTH,
    output [11:0] FB_HEIGHT,
    output [31:0] FB_BASE,
    output [13:0] FB_STRIDE,
    input         FB_VBL,
    input         FB_LL,
    output        FB_FORCE_BLANK,

`ifdef NSX_ENABLE_FB_PAL
    // Palette control for 8bit modes.
    // Ignored for other video modes.
    output        FB_PAL_CLK,
    output [ 7:0] FB_PAL_ADDR,
    output [23:0] FB_PAL_DOUT,
    input  [23:0] FB_PAL_DIN,
    output        FB_PAL_WR,
`endif
`endif

    output LED_USER,  // 1 - ON, 0 - OFF.

    // b[1]: 0 - LED status is system status OR'd with b[0]
    //       1 - LED status is controled solely by b[0]
    // hint: supply 2'b00 to let the system control the LED.
    output [1:0] LED_POWER,
    output [1:0] LED_DISK,

    // I/O board button press simulation (active high)
    // b[1]: user button
    // b[0]: osd button
    output [1:0] BUTTONS,

    input         CLK_AUDIO,  // 24.576 MHz
    output [15:0] AUDIO_L,
    output [15:0] AUDIO_R,
    output        AUDIO_S,    // 1 - signed audio samples, 0 - unsigned
    output [ 1:0] AUDIO_MIX,  // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

    //ADC
    inout [3:0] ADC_BUS,

    //SD-SPI
    output SD_SCK,
    output SD_MOSI,
    input  SD_MISO,
    output SD_CS,
    input  SD_CD,

    //High latency DDR3 RAM interface
    //Use for non-critical time purposes
    output        DDRAM_CLK,
    input         DDRAM_BUSY,
    output [ 7:0] DDRAM_BURSTCNT,
    output [28:0] DDRAM_ADDR,
    input  [63:0] DDRAM_DOUT,
    input         DDRAM_DOUT_READY,
    output        DDRAM_RD,
    output [63:0] DDRAM_DIN,
    output [ 7:0] DDRAM_BE,
    output        DDRAM_WE,

    //SDRAM interface with lower latency
    output        SDRAM_CLK,
    output        SDRAM_CKE,
    output [12:0] SDRAM_A,
    output [ 1:0] SDRAM_BA,
    inout  [15:0] SDRAM_DQ,
    output        SDRAM_DQML,
    output        SDRAM_DQMH,
    output        SDRAM_nCS,
    output        SDRAM_nCAS,
    output        SDRAM_nRAS,
    output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
    //Secondary SDRAM
    //Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
    input         SDRAM2_EN,
    output        SDRAM2_CLK,
    output [12:0] SDRAM2_A,
    output [ 1:0] SDRAM2_BA,
    inout  [15:0] SDRAM2_DQ,
    output        SDRAM2_nCS,
    output        SDRAM2_nCAS,
    output        SDRAM2_nRAS,
    output        SDRAM2_nWE,
`endif

    input  UART_CTS,
    output UART_RTS,
    input  UART_RXD,
    output UART_TXD,
    output UART_DTR,
    input  UART_DSR,

    // Open-drain User port.
    // 0 - D+/RX
    // 1 - D-/TX
    // 2..6 - USR2..USR6
    // Set USER_OUT to 1 to read from USER_IN.
    input  [6:0] USER_IN,
    output [6:0] USER_OUT,

    input OSD_STATUS
);

  // Tie pins not being used
  assign ADC_BUS = 'Z;
  assign USER_OUT = '1;
  assign {UART_RTS, UART_TXD, UART_DTR} = 0;
  assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
  assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;

  // Default values for ports not used in this core
  assign VGA_SL = 0;
  assign VGA_F1 = 0;
  assign VGA_SCALER = 0;
  assign VGA_DISABLE = 0;
  assign HDMI_FREEZE = 0;

  assign AUDIO_MIX = 0;

  assign LED_DISK = 0;
  assign LED_POWER = 0;
  assign BUTTONS = 0;

  //////////////////////////////////////////////////////////////////

  assign VIDEO_ARX = 13'd1;
  assign VIDEO_ARY = 13'd1;

  `include "build_id.vh"
  localparam CONF_STR = {
    // Savestates are located in DDRAM, starting at 0x3E00_0000, and start at every 0x1000 chunk of memory
    "Tamagotchi;SS3E000000:1000;",
    // We load ROMs as if there were multiple options so that we can use the builtin savestate functionality
    "FS0,binb  ,Load ROM;",
    "-;",

    "h0O[38:37],Savestate Slot,1,2,3,4;",
    // Shown only when rom_ready. Save on 28, restore on 29
    "h0RS,Save state (Alt-F1);",
    "h0RT,Restore state (F1);",
    "-;",

    "O[1],Sound,On,Off;",
    "-;",

    "O[4:2],System Speed,1x,2x,4x,50x,Max;",
    "O[5],End Turbo on Event,On,Off;",
    "O[6],Skip Evt at Turbo Start,On,Off;",
    "-;",

    "O[8:7],LCD Type,Sep. Pixels w/BG,Sep. Pixels wo/BG,Solid Pixels;",
    "-;",

    "T[0],Reset (Will delete Tama);",

    "J1,Right Button (Cancel),Bottom Button (Execute),Left Button (Input),Decrease Turbo,Increase Turbo,Savestates;",
    "jn,A,B,Y,L,R;",

    "I,",
    "Slot=DPAD|Save/Load=Start+DPAD,",
    "Active Slot 1,",
    "Active Slot 2,",
    "Active Slot 3,",
    "Active Slot 4,",
    "Save to state 1,",
    "Restore state 1,",
    "Save to state 2,",
    "Restore state 2,",
    "Save to state 3,",
    "Restore state 3,",
    "Save to state 4,",
    "Restore state 4,",
    "v,0;",  // [optional] config version 0-99. 
             // If CONF_STR options are changed in incompatible way, then change version number too,
    // so all options will get default values on first start.
    "V,v",
    `BUILD_DATE
  };

  wire [1:0] buttons;
  wire [127:0] status;
  wire [10:0] ps2_key;

  // Settings
  wire external_reset = status[0];

  wire disable_sound = status[1];

  wire [2:0] interact_turbo_speed = status[4:2];

  wire cancel_turbo_on_event = ~status[5];
  wire suppress_turbo_after_activation = ~status[6];

  wire [1:0] lcd_mode = status[8:7];

  wire [1:0] ss_slot_menu = status[38:37];
  wire [1:0] ss_osd_save_load = status[29:28];

  // Data

  wire ioctl_download;
  wire [15:0] ioctl_index;
  wire ioctl_wr;
  wire [26:0] ioctl_addr;
  wire [15:0] ioctl_dout;

  // While we're actively waiting for image writing, pause ioctl
  wire ioctl_wait = ioctl_image_wr;

  wire sd_rd;
  wire sd_wr;
  wire sd_ack;
  wire [7:0] sd_buff_addr;
  wire [15:0] sd_buff_dout;
  wire [15:0] sd_buff_din;
  wire sd_buff_wr;

  wire img_mounted;
  wire [63:0] img_size;

  wire [15:0] joy_unmod;

  wire ss_status_update;
  wire ss_info_req;
  wire [7:0] ss_info;

  hps_io #(
      .CONF_STR(CONF_STR),
      // Use 16bit data bus
      .WIDE(1)
  ) hps_io (
      .clk_sys  (clk_sys_117_964),
      .HPS_BUS  (HPS_BUS),
      .EXT_BUS  (),
      .gamma_bus(),

      .ioctl_download(ioctl_download),
      .ioctl_index(ioctl_index),
      .ioctl_wr(ioctl_wr),
      .ioctl_addr(ioctl_addr),
      .ioctl_dout(ioctl_dout),
      .ioctl_wait(ioctl_wait),

      .sd_lba('{32'b0}),
      .sd_rd(sd_rd),
      .sd_wr(sd_wr),
      .sd_ack(sd_ack),
      .sd_buff_addr(sd_buff_addr),
      .sd_buff_dout(sd_buff_dout),
      .sd_buff_din('{sd_buff_din}),
      .sd_buff_wr(sd_buff_wr),

      .img_mounted(img_mounted),
      .img_size(img_size),

      .joystick_0(joy_unmod),

      .buttons(buttons),
      .status(status),
      // Used for displaying the savestate menu options
      .status_menumask(rom_ready),
      // Update the OSD selected savestate slot and the turbo speed
      .status_in({status[63:39], ss_slot, status[36:5], turbo_speed, status[1:0]}),
      .status_set(ss_status_update || turbo_status_update),

      .info_req(ss_info_req),
      .info(ss_info),

      .ps2_key(ps2_key)
  );

  // If "Savestates" button is pressed, output nothing to rest of core
  wire [15:0] joy = savestates_button ? 16'b0 : joy_unmod;

  // ~joy[6], ~joy[5], ~joy[4]
  wire left_button = joy[6];
  wire bottom_button = joy[5];
  wire right_button = joy[4];

  wire left_trigger = joy[7];
  wire right_trigger = joy[8];

  wire savestates_button = joy_unmod[9];
  wire savestates_dpad_right = joy_unmod[0];
  wire savestates_dpad_left = joy_unmod[1];
  wire savestates_dpad_down = joy_unmod[2];
  wire savestates_dpad_up = joy_unmod[3];

  ///////////////////////   CLOCKS   ///////////////////////////////

  wire clk_sys_117_964;
  wire clk_vid_13_107;

  pll pll (
      .refclk(CLK_50M),
      .rst(0),
      .outclk_0(clk_sys_117_964),
      .outclk_1(clk_vid_13_107)
  );

  wire rom_download = ioctl_download && ioctl_index == 0;
  wire background_download = ioctl_download && ioctl_index == {10'h1, 6'b0};
  wire spritesheet_download = ioctl_download && ioctl_index == {10'h2, 6'b0};

  wire [15:0] ioctl_dout_reversed = {ioctl_dout[7:0], ioctl_dout[15:8]};

  wire clk_en_32_768khz;
  wire clk_en_65_536khz;

  clock_divider clock_divider (
      .clk(clk_sys_117_964),

      .turbo_speed(turbo_speed),

      .ss_halt(ss_halt),
      .ss_turbo(ss_turbo),
      .ss_begin_reset(ss_begin_reset),

      .clk_en_32_768khz(clk_en_32_768khz),
      .clk_en_65_536khz(clk_en_65_536khz)
  );

  wire reset_turbo;

  wire [2:0] turbo_speed;
  // Represents the turbo value being changed by a "core" mechanic - button press or event reset
  wire show_turbo_ui;

  wire turbo_status_update = prev_turbo_speed != turbo_speed;

  reg [2:0] prev_interact_turbo_speed = 0;
  reg [2:0] prev_turbo_speed = 0;

  always @(posedge clk_sys_117_964) begin
    prev_interact_turbo_speed <= interact_turbo_speed;
    prev_turbo_speed <= turbo_speed;
  end

  turbo_controller turbo_controller (
      .clk(clk_sys_117_964),

      .left_trigger (left_trigger),
      .right_trigger(right_trigger),

      .reset_turbo(reset_turbo),
      .set_turbo(prev_interact_turbo_speed != interact_turbo_speed),
      .turbo_speed_in(interact_turbo_speed),

      .turbo_speed  (turbo_speed),
      .show_turbo_ui(show_turbo_ui)
  );

  wire [12:0] rom_addr;
  reg [11:0] rom_data = 0;

  // ROM is 16 bit
  reg [15:0] rom[8192];

  always @(posedge clk_sys_117_964) begin
    // ROM access
    rom_data <= rom[rom_addr][11:0];
  end

  reg prev_rom_download = 0;
  reg rom_ready = 0;

  always @(posedge clk_sys_117_964) begin
    prev_rom_download <= rom_download;

    // ROM initialization
    if (ioctl_wr && rom_download) begin
      // Word addressing
      rom[ioctl_addr[13:1]] <= ioctl_dout_reversed;
    end

    if (~rom_download && prev_rom_download) begin
      // We've finished downloading the ROM
      rom_ready <= 1;
    end
  end

  wire buzzer;

  reg [2:0] savestate_reset_tick_count = 0;

  wire ss_reset = savestate_reset_tick_count > 0;

  always @(posedge clk_sys_117_964) begin
    if (ss_begin_reset) begin
      // Savestate reset started. Wait for 4 clk_2x_en to occur
      savestate_reset_tick_count <= 3'h4;
    end

    if (savestate_reset_tick_count > 0 && clk_en_65_536khz) begin
      savestate_reset_tick_count <= savestate_reset_tick_count - 1;
    end
  end

  turbo_reset_controller turbo_reset_controller (
      .clk(clk_sys_117_964),
      .clk_en_32_768khz(clk_en_32_768khz),

      // Settings
      .suppress_turbo_after_activation(suppress_turbo_after_activation),
      .cancel_turbo_on_event(cancel_turbo_on_event),

      .turbo_speed(turbo_speed),
      .buzzer(buzzer),

      // Make sure to clear turbo when halting
      .manual_reset_turbo(ss_halt),

      .reset_turbo(reset_turbo)
  );

  cpu_6s46 tamagotchi (
      .clk(clk_sys_117_964),
      .clk_en(clk_en_32_768khz),
      .clk_2x_en(clk_en_65_536khz),

      .reset(RESET || external_reset || buttons[1] || rom_download || ss_reset),

      // Left, middle, right
      .input_k0({1'b0, ~left_button, ~bottom_button, ~right_button}),

      .input_k1(4'h0),

      .rom_addr(rom_addr),
      .rom_data(rom_data),

      .video_addr(video_addr),
      .video_data(video_data),

      .buzzer(buzzer),

      // Savestates
      .ss_bus_in(ss_bus_in),
      .ss_bus_addr(ss_bus_addr),
      .ss_bus_wren(ss_bus_wren),
      .ss_bus_reset(ss_bus_reset || external_reset),
      .ss_bus_out(ss_bus_out),

      .ss_ready(ss_ready)
  );

  ////////////////////////////////////////////////////////////////////////////////////////


  // video generation

  // I don't think the scandoubler provides any practical purpose, and it causes timing issues
  // due to requiring a 4x clock (which isn't going to be an int multiple of the 9x sys clock)
  // So it's disabled

  // assign CLK_VIDEO = clk_vid_4x_52_429;

  // reg [1:0] ce_pix_counter = 0;

  // always @(posedge clk_vid_4x_52_429) begin
  //   ce_pix_counter <= ce_pix_counter + 2'h1;
  // end

  // video_mixer #(
  //     .LINE_LENGTH(360)
  // ) video_mixer (
  //     .CLK_VIDEO(CLK_VIDEO),
  //     .CE_PIXEL (CE_PIXEL),

  //     .ce_pix(ce_pix_counter == 0),

  //     .scandoubler(forced_scandoubler),

  //     .R(rgb[23:16]),
  //     .G(rgb[15:8]),
  //     .B(rgb[7:0]),

  //     .HSync (hsync),
  //     .VSync (vsync),
  //     .HBlank(hblank),
  //     .VBlank(vblank),
  //     .VGA_R (VGA_R),
  //     .VGA_G (VGA_G),
  //     .VGA_B (VGA_B),
  //     .VGA_VS(VGA_VS),
  //     .VGA_HS(VGA_HS),
  //     .VGA_DE(VGA_DE)
  // );

  assign CLK_VIDEO = clk_vid_13_107;
  assign VGA_DE = de;
  assign CE_PIXEL = 1;
  assign VGA_HS = hsync;
  assign VGA_VS = vsync;
  assign VGA_R = rgb[23:16];
  assign VGA_G = rgb[15:8];
  assign VGA_B = rgb[7:0];

  wire vsync;
  wire hsync;
  wire de;
  wire vblank;
  wire hblank;
  wire [23:0] rgb;

  reg ioctl_image_wr = 0;
  reg clear_image_wr = 0;

  always @(posedge clk_sys_117_964) begin
    if (ioctl_wr && (background_download || spritesheet_download)) begin
      // Extend write pulse for video clock
      ioctl_image_wr <= 1;
    end else if (clear_image_wr) begin
      ioctl_image_wr <= 0;
    end
  end

  wire [7:0] video_addr;
  wire [3:0] video_data;

  reg write_spritesheet_high = 0;
  reg [7:0] image_pixel_high = 0;

  always @(posedge clk_vid_13_107) begin
    // Always run this, regardless of whether or not its image data
    write_spritesheet_high <= 0;

    clear_image_wr <= 0;

    if (ioctl_image_wr) begin
      // Mark word as written
      clear_image_wr <= 1;

      image_pixel_high <= ioctl_dout[15:8];
      write_spritesheet_high <= spritesheet_download;
    end
  end

  wire [16:0] spritesheet_write_addr = ioctl_addr[16:0] + {16'b0, write_spritesheet_high};
  wire [15:0] spritesheet_write_data = write_spritesheet_high ? {8'b0, image_pixel_high} : ioctl_dout;

  video video (
      .clk(clk_vid_13_107),

      .video_addr(video_addr),
      .video_data(video_data),

      .background_write_en(ioctl_image_wr && background_download),
      .spritesheet_write_en((ioctl_image_wr || write_spritesheet_high) && spritesheet_download),
      // Top bit is used to determine which memory it goes to
      .image_write_addr(spritesheet_download ? spritesheet_write_addr : ioctl_addr[17:1]),
      .image_write_data(spritesheet_download ? spritesheet_write_data : ioctl_dout_reversed),

      // Settings
      .show_pixel_dividers(lcd_mode != 2),
      .show_pixel_grid_background(lcd_mode == 0),

      .show_turbo_ui(show_turbo_ui),
      .turbo_speed  (turbo_speed),

      .vsync(vsync),
      .hsync(hsync),
      .de(de),
      .vblank(vblank),
      .hblank(hblank),
      .rgb(rgb)
  );

  ///////////////////////////////////////////////

  assign AUDIO_S = 0;
  assign AUDIO_L = ~disable_sound && turbo_speed < 2 ? {2'b0, {14{buzzer}}} : 16'b0;
  assign AUDIO_R = AUDIO_L;

  ///////////////////////////////////////////////

  wire ss_save;
  wire ss_load;

  wire [1:0] ss_slot;

  wire [31:0] ss_bus_in;
  wire [31:0] ss_bus_addr;
  wire ss_bus_wren;
  wire ss_bus_reset;
  wire [31:0] ss_bus_out;

  wire ss_ready;
  wire ss_halt;
  wire ss_begin_reset;
  wire ss_turbo;

  reg begin_save = 0;

  localparam OSD_SAVE_DELAY = {26{1'b1}};
  reg [25:0] osd_save_timer = 0;

  reg prev_osd = 0;

  always @(posedge clk_sys_117_964) begin
    prev_osd   <= OSD_STATUS;

    begin_save <= 0;

    if (osd_save_timer > 0) begin
      osd_save_timer <= osd_save_timer - 26'h1;
    end

    if (OSD_STATUS && ~prev_osd && rom_ready && osd_save_timer == 0) begin
      begin_save <= 1;
    end else if (prev_osd && ~OSD_STATUS) begin
      // Enforce min time before another save can occur
      // ~0.5s at 117MHz
      osd_save_timer <= OSD_SAVE_DELAY;
    end
  end

  savestate_controller savestate_controller (
      .clk(clk_sys_117_964),

      .reset(RESET),

      .slot(ss_slot),

      // Triggers
      .manual_start_savestate_create(ss_save),
      .auto_start_savestate_create(begin_save),
      .manual_start_savestate_load(ss_load),
      // Automatically load once we've downloaded ROM and mounted image
      // `img_mounted` will pulse for ~100 cycles during the end of `rom_download`
      // `img_size` indicates whether or not an actual savestate is present
      .auto_start_savestate_load(rom_download && img_mounted && img_size > 0),

      // SD Saves
      .sd_wr(sd_wr),
      .sd_rd(sd_rd),

      .sd_ack(sd_ack),
      .sd_buff_addr(sd_buff_addr),
      .sd_buff_dout(sd_buff_dout),
      .sd_buff_din(sd_buff_din),
      .sd_buff_wr(sd_buff_wr),

      // DDR
      .DDRAM_CLK(DDRAM_CLK),
      .DDRAM_BUSY(DDRAM_BUSY),
      .DDRAM_BURSTCNT(DDRAM_BURSTCNT),
      .DDRAM_ADDR(DDRAM_ADDR),
      .DDRAM_DOUT(DDRAM_DOUT),
      .DDRAM_DOUT_READY(DDRAM_DOUT_READY),
      .DDRAM_RD(DDRAM_RD),
      .DDRAM_DIN(DDRAM_DIN),
      .DDRAM_BE(DDRAM_BE),
      .DDRAM_WE(DDRAM_WE),

      // Savestate bus
      .bus_in(ss_bus_in),
      .bus_addr(ss_bus_addr),
      .bus_wren(ss_bus_wren),
      .bus_reset(ss_bus_reset),
      .bus_out(ss_bus_out),

      .ss_ready(ss_ready),
      .ss_halt(ss_halt),
      .ss_begin_reset(ss_begin_reset),
      .ss_turbo(ss_turbo)
  );

  savestate_ui #(
      .INFO_TIMEOUT_BITS(25)
  ) savestate_ui (
      .clk          (clk_sys_117_964),
      .ps2_key      (ps2_key[10:0]),
      .allow_ss     (rom_ready),
      .joySS        (savestates_button),
      .joyRight     (savestates_dpad_right),
      .joyLeft      (savestates_dpad_left),
      .joyDown      (savestates_dpad_down),
      .joyUp        (savestates_dpad_up),
      .joyRewind    (0),
      .rewindEnable (0),
      .status_slot  (ss_slot_menu),
      .autoincslot  (0),
      .OSD_saveload (ss_osd_save_load),
      .ss_save      (ss_save),
      .ss_load      (ss_load),
      .ss_info_req  (ss_info_req),
      .ss_info      (ss_info),
      .statusUpdate (ss_status_update),
      .selected_slot(ss_slot)
  );

endmodule
