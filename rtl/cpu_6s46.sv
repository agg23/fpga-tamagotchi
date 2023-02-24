module cpu_6s46 (
    input wire clk,
    input wire clk_2x,

    input wire reset_n,

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

  reg  reset_clock_timer = 0;

  wire timer_128hz;
  wire timer_64hz;
  wire timer_32hz;
  wire timer_16hz;
  wire timer_8hz;
  wire timer_4hz;
  wire timer_2hz;
  wire timer_1hz;

  timers timers (
      .clk(clk),

      .reset_n(reset_n),

      .reset_clock_timer(reset_clock_timer),

      .timer_128hz(timer_128hz),
      .timer_64hz (timer_64hz),
      .timer_32hz (timer_32hz),
      .timer_16hz (timer_16hz),
      .timer_8hz  (timer_8hz),
      .timer_4hz  (timer_4hz),
      .timer_2hz  (timer_2hz),
      .timer_1hz  (timer_1hz)
  );

  // Interrupt masks
  reg [3:0] clock_mask = 0;

  reg reset_clock_factor = 0;
  wire [3:0] clock_factor;

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

      // Factor flags
      .reset_clock_factor(reset_clock_factor),
      .clock_factor(clock_factor),

      .interrupt_req(interrupt_req)
  );

  // Unused registers
  reg [3:0] oscillation = 0;

  // RAM bus
  always @(posedge clk) begin
    if (~reset_n) begin
      reset_clock_factor <= 0;
      reset_clock_timer <= 0;

      clock_mask <= 0;

      oscillation <= 0;
    end else begin
      reset_clock_factor <= 0;
      reset_clock_timer  <= 0;

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
            8'h76, 1'b1
          } : begin
            // Timer reset
            if (memory_write_data[1]) begin
              // Reset clock timer
              reset_clock_timer <= 1;
            end
            if (memory_write_data[0]) begin
              // TODO: Reset watchdog timer
            end
          end
        endcase
      end
    end
  end

endmodule
