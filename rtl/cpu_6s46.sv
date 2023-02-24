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

      // TODO
      .interrupt_req(15'b0)
  );

  wire timer_128hz;
  wire timer_64hz;
  wire timer_32hz;
  wire timer_16hz;
  wire timer_8hz;
  wire timer_4hz;
  wire timer_2hz;
  wire timer_1hz;

  clock clock (
      .clk(clk),

      .reset_n(reset_n),

      .timer_128hz(timer_128hz),
      .timer_64hz (timer_64hz),
      .timer_32hz (timer_32hz),
      .timer_16hz (timer_16hz),
      .timer_8hz  (timer_8hz),
      .timer_4hz  (timer_4hz),
      .timer_2hz  (timer_2hz),
      .timer_1hz  (timer_1hz)
  );

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

      // Factor flags
      .reset_clock_factor(reset_clock_factor),
      .clock_factor(clock_factor)
  );

  // Unused registers
  reg [3:0] oscillation = 0;

  // RAM bus
  always @(posedge clk) begin
    reset_clock_factor <= 0;

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
      casex (memory_addr[7:0])
        8'h00: begin
          // Clock interrupt factor
          if (~memory_write_en) begin
            // Writing not allowed
            memory_read_data   <= clock_factor;
            reset_clock_factor <= 1;
          end
        end
        8'h70: begin
          // Oscillation control
          // Unimplemented
          if (memory_write_en) begin
            oscillation <= memory_write_data;
          end else begin
            memory_read_data <= oscillation;
          end

          $display("Warning: RAM 0xF70 is unimplemented");
        end
      endcase
    end
  end

endmodule
