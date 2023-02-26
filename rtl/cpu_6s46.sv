module cpu_6s46 (
    input wire clk,
    input wire clk_2x,

    input wire reset_n,

    input wire [3:0] input_k0,
    input wire [3:0] input_k1,

    output wire [12:0] rom_addr,
    input  wire [11:0] rom_data
);
  wire memory_write_en;
  wire [11:0] memory_addr;
  wire [3:0] memory_write_data;
  reg [3:0] memory_read_data;

  // RAM from 0x000 - 0x280
  reg [3:0] ram[256+256+128];

  wire [14:0] interrupt_req;

  cpu core (
      .clk(clk),
      .clk_2x(clk_2x),

      .reset_n(reset_n),

      .rom_addr(rom_addr),
      .rom_data(rom_data),

      .memory_write_en(memory_write_en),
      .memory_addr(memory_addr),
      .memory_write_data(memory_write_data),
      .memory_read_data(memory_read_data),

      .interrupt_req(interrupt_req)
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

      .reset_n(reset_n),

      // TODO
      .input_k03(1'b0),
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
      .prog_timer_factor(prog_timer_factor)
  );

  // Interrupt masks
  reg [3:0] clock_mask = 0;
  reg [1:0] stopwatch_mask = 0;
  reg prog_timer_mask = 0;
  reg [3:0] input_k0_mask = 0;
  reg [3:0] input_k1_mask = 0;

  interrupt interrupt (
      .clk(clk),

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

      .interrupt_req(interrupt_req)
  );

  reg [3:0] input_relation_k0 = 4'hF;

  input_lines input_lines (
      .clk(clk),

      .reset_n(reset_n),

      .input_k0(input_k0),
      .input_k1(input_k1),

      .input_relation_k0(input_relation_k0),
      .input_k0_mask(input_k0_mask),
      .input_k1_mask(input_k1_mask),

      .reset_factor(reset_input_factor),
      .factor_flags(input_factor)
  );

  reg [2:0] lcd_control = 3'b100;

  // Unused registers
  reg [2:0] svd_status = 0;
  reg heavy_load_protection = 0;
  reg serial_mask = 0;
  reg [3:0] oscillation = 0;

  // RAM bus
  always @(posedge clk) begin
    if (~reset_n) begin
      reset_clock_factor <= 0;
      reset_clock_timer <= 0;
      reset_stopwatch <= 0;

      reset_stopwatch_factor <= 0;

      enable_stopwatch <= 0;

      clock_mask <= 0;
      stopwatch_mask <= 0;
      prog_timer_mask <= 0;
      input_k0_mask <= 0;
      input_k1_mask <= 0;

      input_relation_k0 <= 4'hF;

      lcd_control <= 3'b100;

      svd_status <= 0;
      heavy_load_protection <= 0;
      serial_mask <= 0;
      oscillation <= 0;
    end else begin
      reset_clock_timer <= 0;
      reset_stopwatch <= 0;
      reset_prog_timer <= 0;

      reset_clock_factor <= 0;
      reset_stopwatch_factor <= 0;
      reset_prog_timer_factor <= 0;
      reset_input_factor <= 0;

      if (~memory_write_en) begin
        memory_read_data <= 0;
      end

      if (memory_addr < 12'h280) begin
        // Actual RAM space
        if (memory_write_en) begin
          ram[memory_addr[9:0]] <= memory_write_data;
        end else begin
          memory_read_data <= ram[memory_addr[9:0]];
        end
      end else if (memory_addr >= 12'hE00 && memory_addr < 12'hE50) begin
        // Display lower segment
      end else if (memory_addr >= 12'hE80 && memory_addr < 12'hED0) begin
        // Display upper segment
      end else if (memory_addr[11:8] == 4'hF) begin
        // I/O segment
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
            8'h73, 1'bX
          } : begin
            // Supply voltage detection control
            if (memory_write_en) begin
              svd_status <= memory_write_data[2:0];
            end else begin
              // Battery is always good
              memory_read_data <= {1'b1, svd_status};
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
        endcase
      end
    end
  end

endmodule
