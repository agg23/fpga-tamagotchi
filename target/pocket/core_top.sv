//
// User core top-level
//
// Instantiated by the real top-level: apf_top
//

`default_nettype none

module core_top (

    //
    // physical connections
    //

    ///////////////////////////////////////////////////
    // clock inputs 74.25mhz. not phase aligned, so treat these domains as asynchronous

    input wire clk_74a,  // mainclk1
    input wire clk_74b,  // mainclk1 

    ///////////////////////////////////////////////////
    // cartridge interface
    // switches between 3.3v and 5v mechanically
    // output enable for multibit translators controlled by pic32

    // GBA AD[15:8]
    inout  wire [7:0] cart_tran_bank2,
    output wire       cart_tran_bank2_dir,

    // GBA AD[7:0]
    inout  wire [7:0] cart_tran_bank3,
    output wire       cart_tran_bank3_dir,

    // GBA A[23:16]
    inout  wire [7:0] cart_tran_bank1,
    output wire       cart_tran_bank1_dir,

    // GBA [7] PHI#
    // GBA [6] WR#
    // GBA [5] RD#
    // GBA [4] CS1#/CS#
    //     [3:0] unwired
    inout  wire [7:4] cart_tran_bank0,
    output wire       cart_tran_bank0_dir,

    // GBA CS2#/RES#
    inout  wire cart_tran_pin30,
    output wire cart_tran_pin30_dir,
    // when GBC cart is inserted, this signal when low or weak will pull GBC /RES low with a special circuit
    // the goal is that when unconfigured, the FPGA weak pullups won't interfere.
    // thus, if GBC cart is inserted, FPGA must drive this high in order to let the level translators
    // and general IO drive this pin.
    output wire cart_pin30_pwroff_reset,

    // GBA IRQ/DRQ
    inout  wire cart_tran_pin31,
    output wire cart_tran_pin31_dir,

    // infrared
    input  wire port_ir_rx,
    output wire port_ir_tx,
    output wire port_ir_rx_disable,

    // GBA link port
    inout  wire port_tran_si,
    output wire port_tran_si_dir,
    inout  wire port_tran_so,
    output wire port_tran_so_dir,
    inout  wire port_tran_sck,
    output wire port_tran_sck_dir,
    inout  wire port_tran_sd,
    output wire port_tran_sd_dir,

    ///////////////////////////////////////////////////
    // cellular psram 0 and 1, two chips (64mbit x2 dual die per chip)

    output wire [21:16] cram0_a,
    inout  wire [ 15:0] cram0_dq,
    input  wire         cram0_wait,
    output wire         cram0_clk,
    output wire         cram0_adv_n,
    output wire         cram0_cre,
    output wire         cram0_ce0_n,
    output wire         cram0_ce1_n,
    output wire         cram0_oe_n,
    output wire         cram0_we_n,
    output wire         cram0_ub_n,
    output wire         cram0_lb_n,

    output wire [21:16] cram1_a,
    inout  wire [ 15:0] cram1_dq,
    input  wire         cram1_wait,
    output wire         cram1_clk,
    output wire         cram1_adv_n,
    output wire         cram1_cre,
    output wire         cram1_ce0_n,
    output wire         cram1_ce1_n,
    output wire         cram1_oe_n,
    output wire         cram1_we_n,
    output wire         cram1_ub_n,
    output wire         cram1_lb_n,

    ///////////////////////////////////////////////////
    // sdram, 512mbit 16bit

    output wire [12:0] dram_a,
    output wire [ 1:0] dram_ba,
    inout  wire [15:0] dram_dq,
    output wire [ 1:0] dram_dqm,
    output wire        dram_clk,
    output wire        dram_cke,
    output wire        dram_ras_n,
    output wire        dram_cas_n,
    output wire        dram_we_n,

    ///////////////////////////////////////////////////
    // sram, 1mbit 16bit

    output wire [16:0] sram_a,
    inout  wire [15:0] sram_dq,
    output wire        sram_oe_n,
    output wire        sram_we_n,
    output wire        sram_ub_n,
    output wire        sram_lb_n,

    ///////////////////////////////////////////////////
    // vblank driven by dock for sync in a certain mode

    input wire vblank,

    ///////////////////////////////////////////////////
    // i/o to 6515D breakout usb uart

    output wire dbg_tx,
    input  wire dbg_rx,

    ///////////////////////////////////////////////////
    // i/o pads near jtag connector user can solder to

    output wire user1,
    input  wire user2,

    ///////////////////////////////////////////////////
    // RFU internal i2c bus 

    inout  wire aux_sda,
    output wire aux_scl,

    ///////////////////////////////////////////////////
    // RFU, do not use
    output wire vpll_feed,


    //
    // logical connections
    //

    ///////////////////////////////////////////////////
    // video, audio output to scaler
    output wire [23:0] video_rgb,
    output wire        video_rgb_clock,
    output wire        video_rgb_clock_90,
    output wire        video_de,
    output wire        video_skip,
    output wire        video_vs,
    output wire        video_hs,

    output wire audio_mclk,
    input  wire audio_adc,
    output wire audio_dac,
    output wire audio_lrck,

    ///////////////////////////////////////////////////
    // bridge bus connection
    // synchronous to clk_74a
    output wire        bridge_endian_little,
    input  wire [31:0] bridge_addr,
    input  wire        bridge_rd,
    output reg  [31:0] bridge_rd_data,
    input  wire        bridge_wr,
    input  wire [31:0] bridge_wr_data,

    ///////////////////////////////////////////////////
    // controller data
    // 
    // key bitmap:
    //   [0]    dpad_up
    //   [1]    dpad_down
    //   [2]    dpad_left
    //   [3]    dpad_right
    //   [4]    face_a
    //   [5]    face_b
    //   [6]    face_x
    //   [7]    face_y
    //   [8]    trig_l1
    //   [9]    trig_r1
    //   [10]   trig_l2
    //   [11]   trig_r2
    //   [12]   trig_l3
    //   [13]   trig_r3
    //   [14]   face_select
    //   [15]   face_start
    // joy values - unsigned
    //   [ 7: 0] lstick_x
    //   [15: 8] lstick_y
    //   [23:16] rstick_x
    //   [31:24] rstick_y
    // trigger values - unsigned
    //   [ 7: 0] ltrig
    //   [15: 8] rtrig
    //
    input wire [15:0] cont1_key,
    input wire [15:0] cont2_key,
    input wire [15:0] cont3_key,
    input wire [15:0] cont4_key,
    input wire [31:0] cont1_joy,
    input wire [31:0] cont2_joy,
    input wire [31:0] cont3_joy,
    input wire [31:0] cont4_joy,
    input wire [15:0] cont1_trig,
    input wire [15:0] cont2_trig,
    input wire [15:0] cont3_trig,
    input wire [15:0] cont4_trig

);

  // not using the IR port, so turn off both the LED, and
  // disable the receive circuit to save power
  assign port_ir_tx              = 0;
  assign port_ir_rx_disable      = 1;

  // bridge endianness
  assign bridge_endian_little    = 0;

  // cart is unused, so set all level translators accordingly
  // directions are 0:IN, 1:OUT
  assign cart_tran_bank3         = 8'hzz;
  assign cart_tran_bank3_dir     = 1'b0;
  assign cart_tran_bank2         = 8'hzz;
  assign cart_tran_bank2_dir     = 1'b0;
  assign cart_tran_bank1         = 8'hzz;
  assign cart_tran_bank1_dir     = 1'b0;
  assign cart_tran_bank0         = 4'hf;
  assign cart_tran_bank0_dir     = 1'b1;
  assign cart_tran_pin30         = 1'b0;  // reset or cs2, we let the hw control it by itself
  assign cart_tran_pin30_dir     = 1'bz;
  assign cart_pin30_pwroff_reset = 1'b0;  // hardware can control this
  assign cart_tran_pin31         = 1'bz;  // input
  assign cart_tran_pin31_dir     = 1'b0;  // input

  // link port is input only
  assign port_tran_so            = 1'bz;
  assign port_tran_so_dir        = 1'b0;  // SO is output only
  assign port_tran_si            = 1'bz;
  assign port_tran_si_dir        = 1'b0;  // SI is input only
  assign port_tran_sck           = 1'bz;
  assign port_tran_sck_dir       = 1'b0;  // clock direction can change
  assign port_tran_sd            = 1'bz;
  assign port_tran_sd_dir        = 1'b0;  // SD is input and not used

  // tie off the rest of the pins we are not using
  assign cram0_a                 = 'h0;
  assign cram0_dq                = {16{1'bZ}};
  assign cram0_clk               = 0;
  assign cram0_adv_n             = 1;
  assign cram0_cre               = 0;
  assign cram0_ce0_n             = 1;
  assign cram0_ce1_n             = 1;
  assign cram0_oe_n              = 1;
  assign cram0_we_n              = 1;
  assign cram0_ub_n              = 1;
  assign cram0_lb_n              = 1;

  assign cram1_a                 = 'h0;
  assign cram1_dq                = {16{1'bZ}};
  assign cram1_clk               = 0;
  assign cram1_adv_n             = 1;
  assign cram1_cre               = 0;
  assign cram1_ce0_n             = 1;
  assign cram1_ce1_n             = 1;
  assign cram1_oe_n              = 1;
  assign cram1_we_n              = 1;
  assign cram1_ub_n              = 1;
  assign cram1_lb_n              = 1;

  assign dram_a                  = 'h0;
  assign dram_ba                 = 'h0;
  assign dram_dq                 = {16{1'bZ}};
  assign dram_dqm                = 'h0;
  assign dram_clk                = 'h0;
  assign dram_cke                = 'h0;
  assign dram_ras_n              = 'h1;
  assign dram_cas_n              = 'h1;
  assign dram_we_n               = 'h1;

  assign sram_a                  = 'h0;
  assign sram_dq                 = {16{1'bZ}};
  assign sram_oe_n               = 1;
  assign sram_we_n               = 1;
  assign sram_ub_n               = 1;
  assign sram_lb_n               = 1;

  assign dbg_tx                  = 1'bZ;
  assign user1                   = 1'bZ;
  assign aux_scl                 = 1'bZ;
  assign vpll_feed               = 1'bZ;


  // for bridge write data, we just broadcast it to all bus devices
  // for bridge read data, we have to mux it
  // add your own devices here
  always @(*) begin
    casex (bridge_addr)
      default: begin
        bridge_rd_data <= 0;
      end
      32'h100: bridge_rd_data <= {29'b0, turbo_speed};
      32'h4xxxxxxx: begin
        bridge_rd_data <= save_state_bridge_read_data;
      end
      32'hF8xxxxxx: begin
        bridge_rd_data <= cmd_bridge_rd_data;
      end
    endcase
  end

  reg interact_set_turbo = 0;
  reg [2:0] interact_turbo_speed = 0;

  always @(posedge clk_74a) begin
    interact_set_turbo <= 0;

    if (reset_delay > 0) begin
      reset_delay <= reset_delay - 1;
    end

    if (bridge_wr) begin
      casex (bridge_addr)
        32'h0: begin
          reset_delay <= 32'h100000;
        end
        32'h10: begin
          disable_sound <= bridge_wr_data[0];
        end
        32'h100: begin
          interact_turbo_speed <= bridge_wr_data[2:0];
          interact_set_turbo   <= 1;
        end
        32'h104: begin
          cancel_turbo_on_event <= bridge_wr_data[0];
        end
        32'h108: begin
          suppress_turbo_after_activation <= bridge_wr_data[0];
        end
        32'h200: begin
          lcd_mode <= bridge_wr_data[1:0];
        end
      endcase
    end
  end

  wire [2:0] turbo_speed;
  // Represents the turbo value being changed by a "core" mechanic - button press or event reset
  wire show_turbo_ui;

  turbo_controller turbo_controller (
      .clk(clk_74a),

      .left_trigger (cont1_key[8]),
      .right_trigger(cont1_key[9]),

      .reset_turbo(reset_turbo_s),
      .set_turbo(interact_set_turbo),
      .turbo_speed_in(interact_turbo_speed),

      .turbo_speed  (turbo_speed),
      .show_turbo_ui(show_turbo_ui)
  );

  wire reset_turbo_s;

  synch_3 #(
      .WIDTH(1)
  ) bridge_resets_s (
      reset_turbo,
      reset_turbo_s,
      clk_74a
  );

  //
  // host/target command handler
  //
  wire reset_n;  // driven by host commands, can be used as core-wide reset
  wire [31:0] cmd_bridge_rd_data;

  wire pll_core_locked_s;
  wire pll_core_locked_sys_s;
  synch_3 s01 (
      pll_core_locked,
      pll_core_locked_s,
      clk_74a
  );

  synch_3 s02 (
      pll_core_locked,
      pll_core_locked_sys_s,
      clk_sys_117_964
  );

  // bridge host commands
  // synchronous to clk_74a
  wire status_boot_done = pll_core_locked_s;
  wire status_setup_done = pll_core_locked_s;  // rising edge triggers a target command
  wire status_running = reset_n;  // we are running as soon as reset_n goes high

  wire dataslot_requestread;
  wire [15:0] dataslot_requestread_id;
  wire dataslot_requestread_ack = 1;
  wire dataslot_requestread_ok = 1;

  wire dataslot_requestwrite;
  wire [15:0] dataslot_requestwrite_id;
  wire dataslot_requestwrite_ack = 1;
  wire dataslot_requestwrite_ok = 1;

  wire dataslot_allcomplete;

  wire savestate_supported = 1;
  wire [31:0] savestate_addr = 32'h40000000;
  wire [31:0] savestate_size = 32'h1D0;
  wire [31:0] savestate_maxloadsize = savestate_size;

  wire savestate_start;
  wire savestate_start_ack;
  wire savestate_start_busy;
  wire savestate_start_ok;
  wire savestate_start_err;

  wire savestate_load;
  wire savestate_load_ack;
  wire savestate_load_busy;
  wire savestate_load_ok;
  wire savestate_load_err;

  wire osnotify_inmenu;

  // bridge target commands
  // synchronous to clk_74a


  // bridge data slot access

  reg [9:0] datatable_addr;
  reg datatable_wren;
  reg [31:0] datatable_data;
  wire [31:0] datatable_q;

  core_bridge_cmd icb (

      .clk    (clk_74a),
      .reset_n(reset_n),

      .bridge_endian_little(bridge_endian_little),
      .bridge_addr         (bridge_addr),
      .bridge_rd           (bridge_rd),
      .bridge_rd_data      (cmd_bridge_rd_data),
      .bridge_wr           (bridge_wr),
      .bridge_wr_data      (bridge_wr_data),

      .status_boot_done (status_boot_done),
      .status_setup_done(status_setup_done),
      .status_running   (status_running),

      .dataslot_requestread    (dataslot_requestread),
      .dataslot_requestread_id (dataslot_requestread_id),
      .dataslot_requestread_ack(dataslot_requestread_ack),
      .dataslot_requestread_ok (dataslot_requestread_ok),

      .dataslot_requestwrite    (dataslot_requestwrite),
      .dataslot_requestwrite_id (dataslot_requestwrite_id),
      .dataslot_requestwrite_ack(dataslot_requestwrite_ack),
      .dataslot_requestwrite_ok (dataslot_requestwrite_ok),

      .dataslot_allcomplete(dataslot_allcomplete),

      .savestate_supported  (savestate_supported),
      .savestate_addr       (savestate_addr),
      .savestate_size       (savestate_size),
      .savestate_maxloadsize(savestate_maxloadsize),

      .savestate_start     (savestate_start),
      .savestate_start_ack (savestate_start_ack),
      .savestate_start_busy(savestate_start_busy),
      .savestate_start_ok  (savestate_start_ok),
      .savestate_start_err (savestate_start_err),

      .savestate_load     (savestate_load),
      .savestate_load_ack (savestate_load_ack),
      .savestate_load_busy(savestate_load_busy),
      .savestate_load_ok  (savestate_load_ok),
      .savestate_load_err (savestate_load_err),

      .osnotify_inmenu(osnotify_inmenu),

      .datatable_addr(datatable_addr),
      .datatable_wren(datatable_wren),
      .datatable_data(datatable_data),
      .datatable_q   (datatable_q)
  );

  wire [31:0] ss_bus_in;
  wire [31:0] ss_bus_addr;
  wire ss_bus_wren;
  wire ss_bus_reset;
  wire [31:0] ss_bus_out;

  wire ss_ready;
  wire ss_halt;
  wire ss_begin_reset;
  wire ss_turbo;

  wire [31:0] save_state_bridge_read_data;

  save_state_controller save_state_controller (
      .clk_74a(clk_74a),
      .clk_sys(clk_sys_117_964),

      .reset(~pll_core_locked_sys_s),

      // APF
      .bridge_wr(bridge_wr),
      .bridge_rd(bridge_rd),
      .bridge_endian_little(bridge_endian_little),
      .bridge_addr(bridge_addr),
      .bridge_wr_data(bridge_wr_data),
      .save_state_bridge_read_data(save_state_bridge_read_data),

      // APF Savestates
      .savestate_load(savestate_load || restore_savestate_load),
      .savestate_load_ack_s(savestate_load_ack),
      .savestate_load_busy_s(savestate_load_busy),
      .savestate_load_ok_s(savestate_load_ok),
      .savestate_load_err_s(savestate_load_err),

      .savestate_start(savestate_start || trigger_savestate_upload),
      .savestate_start_ack_s(savestate_start_ack),
      .savestate_start_busy_s(savestate_start_busy),
      .savestate_start_ok_s(savestate_start_ok),
      .savestate_start_err_s(savestate_start_err),

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

  reg restore_savestate_load = 0;
  reg did_restore_savestate = 0;
  reg prev_reset_n = 0;

  reg prev_savestate_upload = 0;

  always @(posedge clk_74a) begin
    prev_reset_n <= reset_n;
    restore_savestate_load <= 0;
    prev_savestate_upload <= savestate_upload;

    if (bridge_wr && bridge_addr[31:28] == 4'h4) begin
      did_restore_savestate <= 1;
    end

    if (reset_n && ~prev_reset_n) begin
      // Reset ended
      did_restore_savestate  <= 0;

      restore_savestate_load <= did_restore_savestate;
    end

    trigger_savestate_upload <= 0;

    if (savestate_upload && ~prev_savestate_upload) begin
      trigger_savestate_upload <= 1;
    end
  end

  wire ioctl_rom_wr;
  wire [20:0] ioctl_rom_addr;
  wire [15:0] ioctl_rom_dout;

  wire ioctl_image_wr;
  wire [20:0] ioctl_image_addr;
  wire [15:0] ioctl_image_dout;

  wire rom_download = dataslot_requestwrite_id == 0;
  wire background_download = dataslot_requestwrite_id == 10;
  wire spritesheet_download = dataslot_requestwrite_id == 11;

  // These are for the core power on/off savestates
  // wire savestate_download = dataslot_requestwrite_id == 20;
  wire savestate_upload = dataslot_requestread_id == 20;
  reg trigger_savestate_upload = 0;

  wire rom_download_s;
  wire background_download_s;
  wire spritesheet_download_s;

  synch_3 #(
      .WIDTH(3)
  ) download_s (
      {rom_download, background_download, spritesheet_download},
      {rom_download_s, background_download_s, spritesheet_download_s},
      clk_sys_117_964
  );

  data_loader #(
      .ADDRESS_MASK_UPPER_4(4'h1),
      .ADDRESS_SIZE(18),
      .OUTPUT_WORD_SIZE(2)
  ) rom_data_loader (
      .clk_74a(clk_74a),
      .clk_memory(clk_sys_117_964),

      .bridge_wr(bridge_wr),
      .bridge_endian_little(bridge_endian_little),
      .bridge_addr(bridge_addr),
      .bridge_wr_data(bridge_wr_data),

      .write_en  (ioctl_rom_wr),
      .write_addr(ioctl_rom_addr),
      .write_data(ioctl_rom_dout)
  );

  // Image loader exists because of writes to clk_vid_13_107 domain
  data_loader #(
      .ADDRESS_MASK_UPPER_4(4'h2),
      .ADDRESS_SIZE(18),
      .OUTPUT_WORD_SIZE(2)
  ) image_data_loader (
      .clk_74a(clk_74a),
      .clk_memory(clk_vid_13_107),

      .bridge_wr(bridge_wr),
      .bridge_endian_little(bridge_endian_little),
      .bridge_addr(bridge_addr),
      .bridge_wr_data(bridge_wr_data),

      .write_en  (ioctl_image_wr),
      .write_addr(ioctl_image_addr),
      .write_data(ioctl_image_dout)
  );

  always @(posedge clk_74a or negedge pll_core_locked) begin
    if (~pll_core_locked) begin
      datatable_addr <= 0;
      datatable_data <= 0;
      datatable_wren <= 0;
    end else begin
      // Write sram size half of the time
      datatable_wren <= 1;
      datatable_data <= savestate_size;
      // Data slot index 3, not id 3
      datatable_addr <= 3 * 2 + 1;
    end
  end

  wire [15:0] ioctl_rom_dout_reversed = {ioctl_rom_dout[7:0], ioctl_rom_dout[15:8]};
  wire [15:0] ioctl_image_dout_reversed = {ioctl_image_dout[7:0], ioctl_image_dout[15:8]};

  wire clk_en_32_768khz;
  wire clk_en_65_536khz;

  clock_divider clock_divider (
      .clk(clk_sys_117_964),

      .turbo_speed(turbo_speed_s),

      .ss_halt(ss_halt),
      .ss_turbo(ss_turbo),
      .ss_begin_reset(ss_begin_reset),

      .clk_en_32_768khz(clk_en_32_768khz),
      .clk_en_65_536khz(clk_en_65_536khz)
  );

  wire [12:0] rom_addr;
  reg [11:0] rom_data = 0;

  // ROM is 16 bit
  reg [15:0] rom[8192];

  always @(posedge clk_sys_117_964) begin
    // ROM access
    rom_data <= rom[rom_addr][11:0];
  end

  always @(posedge clk_sys_117_964) begin
    // ROM initialization
    if (ioctl_rom_wr && rom_download_s) begin
      // Word addressing
      rom[ioctl_rom_addr[13:1]] <= ioctl_rom_dout_reversed;
    end
  end

  // Settings
  reg [31:0] reset_delay = 0;
  wire external_reset = reset_delay > 0;

  reg disable_sound = 0;
  reg cancel_turbo_on_event = 0;
  reg suppress_turbo_after_activation = 0;

  reg [1:0] lcd_mode = 0;

  // Synced settings
  wire external_reset_s;
  wire [15:0] cont1_key_s;

  wire disable_sound_s;
  wire [2:0] turbo_speed_s;
  wire show_turbo_ui_s;
  wire cancel_turbo_on_event_s;
  wire suppress_turbo_after_activation_s;

  wire [1:0] lcd_mode_s;

  synch_3 #(
      .WIDTH(32)
  ) cont1_s (
      cont1_key,
      cont1_key_s,
      clk_sys_117_964
  );

  synch_3 #(
      .WIDTH(10)
  ) settings_s (
      {
        lcd_mode,
        suppress_turbo_after_activation,
        cancel_turbo_on_event,
        turbo_speed,
        show_turbo_ui,
        disable_sound,
        external_reset
      },
      {
        lcd_mode_s,
        suppress_turbo_after_activation_s,
        cancel_turbo_on_event_s,
        turbo_speed_s,
        show_turbo_ui_s,
        disable_sound_s,
        external_reset_s
      },
      clk_sys_117_964
  );

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

  wire reset_turbo;

  turbo_reset_controller turbo_reset_controller (
      .clk(clk_sys_117_964),
      .clk_en_32_768khz(clk_en_32_768khz),

      // Settings
      .suppress_turbo_after_activation(suppress_turbo_after_activation_s),
      .cancel_turbo_on_event(cancel_turbo_on_event_s),

      .turbo_speed(turbo_speed_s),
      .buzzer(buzzer),

      // Make sure to clear turbo when halting
      .manual_reset_turbo(ss_halt),

      .reset_turbo(reset_turbo)
  );

  cpu_6s46 tamagotchi (
      .clk(clk_sys_117_964),
      .clk_en(clk_en_32_768khz),
      .clk_2x_en(clk_en_65_536khz),

      .reset(~pll_core_locked_sys_s || external_reset_s || ss_reset),

      // Left, middle, right
      .input_k0({1'b0, ~cont1_key_s[7], ~cont1_key_s[5], ~cont1_key_s[4]}),
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
      .ss_bus_reset(ss_bus_reset || external_reset_s),
      .ss_bus_out(ss_bus_out),

      .ss_ready(ss_ready)
  );

  ////////////////////////////////////////////////////////////////////////////////////////


  // video generation

  wire vsync;
  wire hsync;
  wire de;
  wire [23:0] rgb;

  assign video_rgb_clock = clk_vid_13_107;
  assign video_rgb_clock_90 = clk_vid_13_107_90deg;
  assign video_rgb = de ? rgb : 24'h0;
  assign video_de = de;
  assign video_skip = 0;
  assign video_vs = vsync;
  assign video_hs = hsync;

  wire [7:0] video_addr;
  wire [3:0] video_data;

  reg write_spritesheet_high = 0;
  reg [7:0] image_pixel_high = 0;

  always @(posedge clk_vid_13_107) begin
    // Always run this, regardless of whether or not its image data
    write_spritesheet_high <= 0;

    if (ioctl_image_wr) begin
      image_pixel_high <= ioctl_image_dout[15:8];
      write_spritesheet_high <= spritesheet_download_s;
    end
  end

  wire [16:0] spritesheet_write_addr = ioctl_image_addr[16:0] + {16'b0, write_spritesheet_high};
  wire [15:0] spritesheet_write_data = write_spritesheet_high ? {8'b0, image_pixel_high} : ioctl_image_dout;

  video video (
      .clk(clk_vid_13_107),

      .video_addr(video_addr),
      .video_data(video_data),

      .background_write_en(ioctl_image_wr && background_download_s),
      .spritesheet_write_en((ioctl_image_wr || write_spritesheet_high) && spritesheet_download_s),
      // Top bit is used to determine which memory it goes to
      .image_write_addr(spritesheet_download_s ? spritesheet_write_addr : ioctl_image_addr[17:1]),
      .image_write_data(spritesheet_download_s ? spritesheet_write_data : ioctl_image_dout_reversed),

      // Settings
      .show_pixel_dividers(lcd_mode_s > 0),
      .show_pixel_grid_background(lcd_mode_s == 2),

      .show_turbo_ui(show_turbo_ui_s),
      .turbo_speed  (turbo_speed_s),

      .vsync(vsync),
      .hsync(hsync),
      .de(de),
      .rgb(rgb)
  );

  ///////////////////////////////////////////////

  wire [14:0] audio_l = ~disable_sound_s && turbo_speed_s < 2 ? {2'b0, {13{buzzer}}} : 0;

  sound_i2s #(
      .CHANNEL_WIDTH(15)
  ) sound_i2s (
      .clk_74a  (clk_74a),
      .clk_audio(clk_sys_117_964),

      .audio_l(audio_l),
      .audio_r(audio_l),

      .audio_mclk(audio_mclk),
      .audio_lrck(audio_lrck),
      .audio_dac (audio_dac)
  );

  ///////////////////////////////////////////////

  wire clk_sys_117_964;
  wire clk_vid_13_107;
  wire clk_vid_13_107_90deg;

  wire pll_core_locked;

  mf_pllbase mp1 (
      .refclk(clk_74a),
      .rst   (0),

      .outclk_0(clk_sys_117_964),
      .outclk_1(clk_vid_13_107),
      .outclk_2(clk_vid_13_107_90deg),

      .locked(pll_core_locked)
  );



endmodule
