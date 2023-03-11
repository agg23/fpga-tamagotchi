package ss_addresses;
  parameter SS_BUS_WIDTH = 8;
  parameter SS_DATA_WIDTH = 32;

  localparam WIDTH = SS_BUS_WIDTH - 1;

  // Addresses in savestate
  parameter [WIDTH:0] SS_REGS1 = 8'h0;  // np, pc, a, b, flags: 30
  parameter [WIDTH:0] SS_REGS2 = 8'h1;  // x, y, sp: 32

  parameter [WIDTH:0] SS_CLOCK = 8'h2;  // clock: timer_256_tick, divider, counter_256: 15
  parameter [WIDTH:0] SS_STOPWATCH = 8'h3; // factor_flags, counter_100hz, counter_swh, coutner_swl: 14
  parameter [WIDTH:0] SS_PROG_TIMER = 8'h4;  // factor_flags, downcounter, divider_8khz, counter_8khz: 16

  parameter [WIDTH:0] SS_INTERRUPT = 8'h5;  // prev_timer_32hz, prev_timer_8hz, prev_timer_2hz, prev_timer_1hz, clock_factor: 8
  parameter [WIDTH:0] SS_INPUT = 8'h6;  // factor_flags: 2

  parameter [WIDTH:0] SS_MEMMAP1 = 8'h7; // enable_stopwatch, enable_prog_timer, prog_timer_clock_selection, prog_timer_reload, clock_mask, stopwatch_mask, prog_timer_mask, input_k0_mask, input_k1_mask, input_relation_k0: 32
  parameter [WIDTH:0] SS_MEMMAP2 = 8'h8; // buzzer_output_control, buzzer_frequency_selection, lcd_control, svd_status, heavy_load_protection, serial_mask, serial_data, oscillation, prog_timer_clock_output, buzzer_envelope: 31
  parameter [WIDTH:0] SS_MEMMAP3 = 8'h9;  // lcd_contrast: 4

  parameter [WIDTH:0] SS_MAIN_RAM_START = 8'h10;
  parameter [WIDTH:0] SS_MAIN_RAM_END = 8'h60;  // 80 addresses that map to 640 4-bit addresses

  parameter [WIDTH:0] SS_VIDEO_RAM_START = 8'h60;
  parameter [WIDTH:0] SS_VIDEO_RAM_END = 8'h74;  // 20 addresses that map to 160 4-bit addresses
endpackage
