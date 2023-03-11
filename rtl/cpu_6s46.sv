import ss_addresses::*;

module cpu_6s46 (
    input wire clk,
    input wire clk_vid,

    input wire clk_en,
    input wire clk_2x_en,

    input wire reset_n,

    input wire [3:0] input_k0,
    input wire [3:0] input_k1,

    output wire [12:0] rom_addr,
    input  wire [11:0] rom_data,

    input  wire [7:0] video_addr,
    output wire [3:0] video_data,

    output wire buzzer,

    // Settings
    // Probably unused
    output wire lcd_all_off_setting,
    output wire lcd_all_on_setting,

    // Savestates
    input wire [31:0] ss_bus_in,
    input wire [7:0] ss_bus_addr,
    input wire ss_bus_wren,
    input wire ss_bus_reset_n,
    output wire [31:0] ss_bus_out
);
  // Savestates
  wire [31:0] ss_bus_out_core;
  wire [31:0] ss_bus_out_timers;
  wire [31:0] ss_bus_out_interrupt;
  wire [31:0] ss_bus_out_input;

  wire [31:0] ss_bus_out1;
  wire [31:0] ss_bus_out2;
  wire [31:0] ss_bus_out3;

  wire [31:0] ss_bus_out_main_ram;
  wire [31:0] ss_bus_out_video_ram;

  assign ss_bus_out = ss_bus_out_core 
      | ss_bus_out_timers
      | ss_bus_out_interrupt 
      | ss_bus_out_input 
      | ss_bus_out1 
      | ss_bus_out2 
      | ss_bus_out3 
      | ss_bus_out_main_ram
      | ss_bus_out_video_ram;

  wire memory_write_en;
  wire memory_read_en;
  wire [11:0] memory_addr;
  wire [3:0] memory_write_data;
  reg [3:0] memory_read_data;

  wire [14:0] interrupt_req;

  cpu core (
      .clk(clk),
      .clk_en(clk_en),
      .clk_2x_en(clk_2x_en),

      .reset_n(reset_n),

      .rom_addr(rom_addr),
      .rom_data(rom_data),

      .memory_write_en(memory_write_en),
      .memory_read_en(memory_read_en),
      .memory_addr(memory_addr),
      .memory_write_data(memory_write_data),
      .memory_read_data(memory_read_data),

      .interrupt_req(interrupt_req),

      // Savestates
      .ss_bus_in(ss_bus_in),
      .ss_bus_addr(ss_bus_addr),
      .ss_bus_wren(ss_bus_wren),
      .ss_bus_reset_n(ss_bus_reset_n),
      .ss_bus_out(ss_bus_out_core)
  );

  reg reset_clock_timer = 0;
  reg reset_stopwatch = 0;
  reg reset_prog_timer = 0;

  reg enable_stopwatch = 0;
  reg enable_prog_timer = 0;

  reg reset_clock_factor = 0;
  reg reset_stopwatch_factor = 0;
  reg reset_prog_timer_factor = 0;
  reg reset_input_factor = 0;

  reg [2:0] prog_timer_clock_selection = 0;
  reg [7:0] prog_timer_reload = 0;

  wire timer_128hz;
  wire timer_64hz;
  wire timer_32hz;
  wire timer_16hz;
  wire timer_8hz;
  wire timer_4hz;
  wire timer_2hz;
  wire timer_1hz;

  wire [3:0] stopwatch_swl;
  wire [3:0] stopwatch_swh;
  wire [7:0] prog_timer_downcounter;

  wire [3:0] clock_factor;
  wire [1:0] stopwatch_factor;
  wire prog_timer_factor;
  wire [1:0] input_factor;

  timers timers (
      .clk(clk),
      .clk_en(clk_en),

      .reset_n(reset_n),

      .input_k03(input_k0[3]),
      .prog_timer_clock_selection(prog_timer_clock_selection),
      .prog_timer_reload(prog_timer_reload),

      .reset_clock_timer(reset_clock_timer),
      .reset_stopwatch  (reset_stopwatch),
      .reset_prog_timer (reset_prog_timer),

      .reset_stopwatch_factor (reset_stopwatch_factor),
      .reset_prog_timer_factor(reset_prog_timer_factor),

      .enable_stopwatch (enable_stopwatch),
      .enable_prog_timer(enable_prog_timer),

      .timer_128hz(timer_128hz),
      .timer_64hz (timer_64hz),
      .timer_32hz (timer_32hz),
      .timer_16hz (timer_16hz),
      .timer_8hz  (timer_8hz),
      .timer_4hz  (timer_4hz),
      .timer_2hz  (timer_2hz),
      .timer_1hz  (timer_1hz),

      .stopwatch_swl(stopwatch_swl),
      .stopwatch_swh(stopwatch_swh),
      .prog_timer_downcounter(prog_timer_downcounter),

      .stopwatch_factor (stopwatch_factor),
      .prog_timer_factor(prog_timer_factor),

      // Savestates
      .ss_bus_in(ss_bus_in),
      .ss_bus_addr(ss_bus_addr),
      .ss_bus_wren(ss_bus_wren),
      .ss_bus_reset_n(ss_bus_reset_n),
      .ss_bus_out(ss_bus_out_timers)
  );

  // Interrupt masks
  reg [3:0] clock_mask = 0;
  reg [1:0] stopwatch_mask = 0;
  reg prog_timer_mask = 0;
  reg [3:0] input_k0_mask = 0;
  reg [3:0] input_k1_mask = 0;

  interrupt interrupt (
      .clk(clk),
      .clk_en(clk_en),

      .reset_n(reset_n),

      // Clock
      .timer_32hz(timer_32hz),
      .timer_8hz (timer_8hz),
      .timer_2hz (timer_2hz),
      .timer_1hz (timer_1hz),

      // Masks
      .clock_mask(clock_mask),
      .stopwatch_mask(stopwatch_mask),
      .prog_timer_mask(prog_timer_mask),

      // Factor flags
      .reset_clock_factor(reset_clock_factor),
      .clock_factor(clock_factor),
      .stopwatch_factor(stopwatch_factor),
      .prog_timer_factor(prog_timer_factor),
      .input_factor(input_factor),

      .interrupt_req(interrupt_req),

      // Savestates
      .ss_bus_in(ss_bus_in),
      .ss_bus_addr(ss_bus_addr),
      .ss_bus_wren(ss_bus_wren),
      .ss_bus_reset_n(ss_bus_reset_n),
      .ss_bus_out(ss_bus_out_interrupt)
  );

  reg [3:0] input_relation_k0 = 4'hF;

  input_lines input_lines (
      .clk(clk),
      .clk_en(clk_en),

      .reset_n(reset_n),

      .input_k0(input_k0),
      .input_k1(input_k1),

      .input_relation_k0(input_relation_k0),
      .input_k0_mask(input_k0_mask),
      .input_k1_mask(input_k1_mask),

      .reset_factor(reset_input_factor),
      .factor_flags(input_factor),

      // Savestates
      .ss_bus_in(ss_bus_in),
      .ss_bus_addr(ss_bus_addr),
      .ss_bus_wren(ss_bus_wren),
      .ss_bus_reset_n(ss_bus_reset_n),
      .ss_bus_out(ss_bus_out_input)
  );

  reg [3:0] buzzer_output_control = 4'hF;
  reg [3:0] buzzer_frequency_selection = 4'hF;

  buzzer buzzer_sound (
      .clk(clk),
      .clk_en(clk_en),

      .reset_n(reset_n),

      .buzzer_enabled  (~buzzer_output_control[3]),
      .buzzer_frequency(buzzer_frequency_selection[2:0]),

      .buzzer_output(buzzer)
  );

  reg [2:0] lcd_control = 3'b100;

  // Unused registers
  reg [2:0] svd_status = 0;
  reg heavy_load_protection = 0;
  reg serial_mask = 0;
  reg [7:0] serial_data = 0;
  reg [3:0] oscillation = 0;
  reg prog_timer_clock_output = 0;
  reg [3:0] lcd_contrast = 4'h8;
  reg [1:0] buzzer_envelope = 2'b0;

  // Settings
  assign lcd_all_off_setting = lcd_control[2];
  assign lcd_all_on_setting  = lcd_control[1];

  // RAM bus

  wire cpu_video_write_en = memory_write_en && ((memory_addr >= 12'hE00 && memory_addr < 12'hE50) || (memory_addr >= 12'hE80 && memory_addr < 12'hED0));
  wire [7:0] cpu_video_addr = (memory_addr >= 12'hE00 && memory_addr < 12'hE50) ? {1'b0, memory_addr[6:0]} :
                              (memory_addr >= 12'hE80 && memory_addr < 12'hED0) ? {1'b0, memory_addr[6:0]} + 8'h50 : 8'b0;

  wire [3:0] cpu_video_out;

  wire [7:0] ss_video_ram_addr;
  wire [3:0] ss_video_ram_new_data;
  wire ss_video_ram_wren;
  wire ss_video_ram_active;

  wire [7:0] combined_video_addr = ss_video_ram_active ? ss_video_ram_addr : (video_addr < 8'hA0 ? video_addr : 8'h0);

  // Sys and video RAM split out and not inferred due to massive synthesis size improvement using Quartus
  video_ram video_ram (
      .clock(clk),

      .address_a(cpu_video_addr),
      .data_a(memory_write_data),
      .q_a(cpu_video_out),
      .wren_a(cpu_video_write_en),

      // Video access
      .address_b(combined_video_addr),
      .data_b(ss_video_ram_new_data),
      .q_b(video_data),
      .wren_b(ss_video_ram_wren)
  );

  wire [9:0] ss_main_ram_addr;
  wire [3:0] ss_main_ram_new_data;
  wire ss_main_ram_wren;
  wire ss_main_ram_active;

  wire [9:0] combined_cpu_ram_addr = ss_main_ram_active ? ss_main_ram_addr : memory_addr[9:0];
  wire [3:0] combined_cpu_ram_data = ss_main_ram_active ? ss_main_ram_new_data : memory_write_data;
  wire combined_cpu_ram_wren = ss_main_ram_active ? ss_main_ram_wren : memory_write_en && memory_addr < 12'h280;

  wire [3:0] cpu_ram_out;

  // RAM from 0x000 - 0x280
  main_ram ram (
      .clock(clk),

      .address(combined_cpu_ram_addr),
      .data(combined_cpu_ram_data),
      .q(cpu_ram_out),
      .wren(combined_cpu_ram_wren)
  );

  wire [31:0] ss_current_data1 = {
    enable_stopwatch,
    enable_prog_timer,
    prog_timer_clock_selection,
    prog_timer_reload,
    clock_mask,
    stopwatch_mask,
    prog_timer_mask,
    input_k0_mask,
    input_k1_mask,
    input_relation_k0
  };

  wire [31:0] ss_current_data2 = {
    1'b0,
    buzzer_output_control,
    buzzer_frequency_selection,
    lcd_control,
    svd_status,
    heavy_load_protection,
    serial_mask,
    serial_data,
    oscillation,
    prog_timer_clock_output,
    buzzer_envelope
  };

  wire [31:0] ss_current_data3 = {28'b0, lcd_contrast};

  wire [31:0] ss_new_data1;
  wire [31:0] ss_new_data2;
  wire [31:0] ss_new_data3;

  always @(posedge clk) begin
    if (~reset_n) begin
      reset_clock_factor <= 0;
      reset_clock_timer <= 0;
      reset_stopwatch <= 0;

      reset_stopwatch_factor <= 0;

      { enable_stopwatch,
        enable_prog_timer,
        prog_timer_clock_selection,
        prog_timer_reload,
        clock_mask,
        stopwatch_mask,
        prog_timer_mask,
        input_k0_mask,
        input_k1_mask,
        input_relation_k0
      } <= ss_new_data1;

      {
        buzzer_output_control,
        buzzer_frequency_selection,
        lcd_control,
        svd_status,
        heavy_load_protection,
        serial_mask,
        serial_data,
        oscillation,
        prog_timer_clock_output,
        buzzer_envelope
      } <= ss_new_data2[30:0];

      {lcd_contrast} <= ss_new_data3[3:0];
    end else if (clk_en) begin
      reset_clock_timer <= 0;
      reset_stopwatch <= 0;
      reset_prog_timer <= 0;

      reset_clock_factor <= 0;
      reset_stopwatch_factor <= 0;
      reset_prog_timer_factor <= 0;
      reset_input_factor <= 0;

      if ((memory_write_en || memory_read_en)) begin
        memory_read_data <= 0;

        if (memory_addr < 12'h280) begin
          memory_read_data <= cpu_ram_out;
        end else if (memory_addr >= 12'hE00 && memory_addr < 12'hE50) begin
          // Display lower segment
          memory_read_data <= cpu_video_out;
        end else if (memory_addr >= 12'hE80 && memory_addr < 12'hED0) begin
          // Display upper segment
          memory_read_data <= cpu_video_out;
        end else if (memory_addr[11:8] == 4'hF) begin
          // I/O segment
          // $display("Accessing I/O address 0x%h. Writing: %b", memory_addr, memory_write_en);

          casex ({
            memory_addr[7:0], memory_write_en
          })
            {
              8'h00, 1'b0
            } : begin
              // Clock interrupt factor
              memory_read_data   <= clock_factor;
              reset_clock_factor <= 1;
            end
            {
              8'h01, 1'b0
            } : begin
              // Stopwatch interrupt factor
              memory_read_data <= {2'b0, stopwatch_factor};
              reset_stopwatch_factor <= 1;
            end
            {
              8'h02, 1'b0
            } : begin
              // Programmable timer interrupt factor
              memory_read_data <= {3'b0, prog_timer_factor};
              reset_prog_timer_factor <= 1;
            end
            // {8'h03, 1'b0} Serial interrupt factor
            {
              8'h04, 1'b0
            } : begin
              // Input K0 interrupt factor
              memory_read_data   <= {3'b0, input_factor[0]};
              reset_input_factor <= 1;
            end
            {
              8'h05, 1'b0
            } : begin
              // Input K1 interrupt factor
              memory_read_data   <= {3'b0, input_factor[1]};
              reset_input_factor <= 1;
            end
            {
              8'h10, 1'bX
            } : begin
              // Clock interrupt mask
              if (memory_write_en) begin
                clock_mask <= memory_write_data;
              end else begin
                memory_read_data <= clock_mask;
              end
            end
            {
              8'h11, 1'bX
            } : begin
              // Stopwatch interrupt mask
              if (memory_write_en) begin
                stopwatch_mask <= memory_write_data[1:0];
              end else begin
                memory_read_data <= {2'b0, stopwatch_mask};
              end
            end
            {
              8'h12, 1'bX
            } : begin
              // Programmable timer interrupt mask
              if (memory_write_en) begin
                prog_timer_mask <= memory_write_data[0];
              end else begin
                memory_read_data <= {3'b0, prog_timer_mask};
              end
            end
            {
              8'h13, 1'bX
            } : begin
              // Serial interrupt mask
              if (memory_write_en) begin
                serial_mask <= memory_write_data[0];
              end else begin
                memory_read_data <= {3'b0, serial_mask};
              end
            end
            {
              8'h14, 1'bX
            } : begin
              // Input K0 interrupt mask
              if (memory_write_en) begin
                input_k0_mask <= memory_write_data;
              end else begin
                memory_read_data <= input_k0_mask;
              end
            end
            {
              8'h15, 1'bX
            } : begin
              // Input K1 interrupt mask
              if (memory_write_en) begin
                input_k1_mask <= memory_write_data;
              end else begin
                memory_read_data <= input_k1_mask;
              end
            end
            {
              8'h20, 1'b0
            } : begin
              // Clock timer values (low)
              memory_read_data <= {timer_16hz, timer_32hz, timer_64hz, timer_128hz};
            end
            {
              8'h21, 1'b0
            } : begin
              // Clock timer values (high)
              memory_read_data <= {timer_1hz, timer_2hz, timer_4hz, timer_8hz};
            end
            {
              8'h22, 1'b0
            } : begin
              // Stopwatch 1/100 sec BCD
              memory_read_data <= stopwatch_swl;
            end
            {
              8'h23, 1'b0
            } : begin
              // Stopwatch 1/10 sec BCD
              memory_read_data <= stopwatch_swh;
            end
            {
              8'h24, 1'b0
            } : begin
              // Programmable timer value (low)
              memory_read_data <= prog_timer_downcounter[3:0];
            end
            {
              8'h25, 1'b0
            } : begin
              // Programmable timer value (high)
              memory_read_data <= prog_timer_downcounter[7:4];
            end
            {
              8'h26, 1'bX
            } : begin
              // Programmable timer reload data (low)
              if (memory_write_en) begin
                prog_timer_reload[3:0] <= memory_write_data;
              end else begin
                memory_read_data <= prog_timer_reload[3:0];
              end
            end
            {
              8'h27, 1'bX
            } : begin
              // Programmable timer reload data (high)
              if (memory_write_en) begin
                prog_timer_reload[7:4] <= memory_write_data;
              end else begin
                memory_read_data <= prog_timer_reload[7:4];
              end
            end
            {
              8'h30, 1'bX
            } : begin
              // Serial data (low)
              if (memory_write_en) begin
                serial_data[3:0] <= memory_write_data;
              end else begin
                memory_read_data <= serial_data[3:0];
              end
            end
            {
              8'h31, 1'bX
            } : begin
              // Serial data (high)
              if (memory_write_en) begin
                serial_data[7:4] <= memory_write_data;
              end else begin
                memory_read_data <= serial_data[7:4];
              end
            end
            {
              8'h40, 1'b0
            } : begin
              // Input K0 value
              memory_read_data <= input_k0;
            end
            {
              8'h41, 1'bX
            } : begin
              // Input relation
              if (memory_write_en) begin
                input_relation_k0 <= memory_write_data;
              end else begin
                memory_read_data <= input_relation_k0;
              end
            end
            {
              8'h42, 1'b0
            } : begin
              // Input K1 value
              memory_read_data <= input_k1;
            end
            // 50-53 are unused output ports
            {
              8'h54, 1'bX
            } : begin
              // Output ports R4, buzzer control
              if (memory_write_en) begin
                buzzer_output_control <= memory_write_data;
              end else begin
                memory_read_data <= buzzer_output_control;
              end
            end
            // 60-63 are unused I/O ports
            {
              8'h70, 1'bX
            } : begin
              // Oscillation control
              // Unimplemented
              if (memory_write_en) begin
                oscillation <= memory_write_data;
              end else begin
                memory_read_data <= oscillation;
              end

              $display("Warning: RAM 0xF70 is unimplemented");
            end
            {
              8'h71, 1'bX
            } : begin
              // LCD control and heavy load protection
              if (memory_write_en) begin
                {lcd_control, heavy_load_protection} <= memory_write_data;
              end else begin
                memory_read_data <= {lcd_control, heavy_load_protection};
              end
            end
            {
              8'h72, 1'bX
            } : begin
              // LCD contrast
              if (memory_write_en) begin
                lcd_contrast <= memory_write_data;
              end else begin
                memory_read_data <= lcd_contrast;
              end
            end
            {
              8'h73, 1'bX
            } : begin
              // Supply voltage detection control
              if (memory_write_en) begin
                svd_status <= memory_write_data[2:0];
              end else begin
                // Battery is always good, so when voltage detection is off, battery low field is on (in spec), and when on, it's always low
                memory_read_data <= {~svd_status[2], svd_status};
              end
            end
            {
              8'h74, 1'bX
            } : begin
              // Buzzer frequency
              if (memory_write_en) begin
                buzzer_frequency_selection <= memory_write_data;
              end else begin
                memory_read_data <= buzzer_frequency_selection;
              end
            end
            {
              8'h75, 1'bX
            } : begin
              // Buzzer settings
              if (memory_write_en) begin
                // TODO: Handle trigger and reset
                buzzer_envelope <= memory_write_data[1:0];
              end else begin
                memory_read_data <= {2'b0, buzzer_envelope};
              end
            end
            {
              8'h76, 1'b1
            } : begin
              // Timer reset
              if (memory_write_data[1]) begin
                // Reset clock timer
                reset_clock_timer <= 1;
              end
              if (memory_write_data[0]) begin
                // TODO: Reset watchdog timer, purposefully omitted
              end
            end
            {
              8'h77, 1'bX
            } : begin
              // Stopwatch reset/pause
              if (memory_write_en) begin
                {reset_stopwatch, enable_stopwatch} <= memory_write_data[1:0];
              end else begin
                memory_read_data <= {3'b0, enable_stopwatch};
              end
            end
            {
              8'h78, 1'bX
            } : begin
              // Programmable timer reset/start/stop
              if (memory_write_en) begin
                {reset_prog_timer, enable_prog_timer} <= memory_write_data[1:0];
              end else begin
                memory_read_data <= {3'b0, enable_prog_timer};
              end
            end
            {
              8'h79, 1'bX
            } : begin
              // Programmable timer clock selection
              if (memory_write_en) begin
                {prog_timer_clock_output, prog_timer_clock_selection} <= memory_write_data;
              end else begin
                memory_read_data <= {prog_timer_clock_output, prog_timer_clock_selection};
              end
            end
            // 7A-7E is unused I/O
            default: begin
              $display("Unused I/O access at 0x%h. Writing: %b", memory_addr, memory_write_en);
            end
          endcase
        end else begin
          $display("Unhandled memory access at 0x%h. Writing: %b", memory_addr, memory_write_en);
        end
      end
    end
  end

  bus_connector #(
      .ADDRESS(SS_MEMMAP1),
      // Last 4 bits are input_relation_k0
      .DEFAULT_VALUE({28'b0, 4'hF})
  ) ss1 (
      .clk(clk),

      .bus_in(ss_bus_in),
      .bus_addr(ss_bus_addr),
      .bus_wren(ss_bus_wren),
      .bus_reset_n(ss_bus_reset_n),
      .bus_out(ss_bus_out1),

      .current_data(ss_current_data1),
      .new_data(ss_new_data1)
  );

  bus_connector #(
      .ADDRESS(SS_MEMMAP2),
      // {1'b0, buzzer_output_control, buzzer_frequency_selection, lcd_control, svd_status, heavy_load_protection, serial_mask, serial_data, oscillation, prog_timer_clock_output, buzzer_envelope}
      .DEFAULT_VALUE({1'b0, 4'hF, 4'hF, 3'b100, 20'b0})
  ) ss2 (
      .clk(clk),

      .bus_in(ss_bus_in),
      .bus_addr(ss_bus_addr),
      .bus_wren(ss_bus_wren),
      .bus_reset_n(ss_bus_reset_n),
      .bus_out(ss_bus_out2),

      .current_data(ss_current_data2),
      .new_data(ss_new_data2)
  );

  bus_connector #(
      .ADDRESS(SS_MEMMAP3),
      // {lcd_contrast}
      .DEFAULT_VALUE({28'b0, 4'h8})
  ) ss3 (
      .clk(clk),

      .bus_in(ss_bus_in),
      .bus_addr(ss_bus_addr),
      .bus_wren(ss_bus_wren),
      .bus_reset_n(ss_bus_reset_n),
      .bus_out(ss_bus_out3),

      .current_data(ss_current_data3),
      .new_data(ss_new_data3)
  );

  bus_memory #(
      .MEM_ADDR_WIDTH(10),
      .ADDRESS_MIN(SS_MAIN_RAM_START),
      .ADDRESS_MAX(SS_MAIN_RAM_END)
  ) ss_main_ram (
      .clk(clk),

      .bus_in(ss_bus_in),
      .bus_addr(ss_bus_addr),
      .bus_wren(ss_bus_wren),
      .bus_reset_n(ss_bus_reset_n),
      .bus_out(ss_bus_out_main_ram),

      .mem_addr(ss_main_ram_addr),
      .mem_current_data(cpu_ram_out),
      .mem_new_data(ss_main_ram_new_data),
      .mem_wren(ss_main_ram_wren),
      .mem_active(ss_main_ram_active)
  );

  bus_memory #(
      .MEM_ADDR_WIDTH(8),
      .ADDRESS_MIN(SS_VIDEO_RAM_START),
      .ADDRESS_MAX(SS_VIDEO_RAM_END)
  ) ss_video_ram (
      .clk(clk),

      .bus_in(ss_bus_in),
      .bus_addr(ss_bus_addr),
      .bus_wren(ss_bus_wren),
      .bus_reset_n(ss_bus_reset_n),
      .bus_out(ss_bus_out_video_ram),

      .mem_addr(ss_video_ram_addr),
      .mem_current_data(video_data),
      .mem_new_data(ss_video_ram_new_data),
      .mem_wren(ss_video_ram_wren),
      .mem_active(ss_video_ram_active)
  );
endmodule
