`timescale 1ps / 1ps

module tama_tb;

  reg clk = 0;
  // reg clk_2x = 1;

  reg reset_n = 0;

  wire [12:0] rom_addr;
  reg [11:0] rom_data;

  // ROM is 16 bit
  reg [15:0] rom[8192];

  initial $readmemh("C:/Users/adam/code/fpga/tamagotchi/bass/tama.hex", rom);

  reg [7:0] divider = 8'd50;

  wire clk_en = divider == 0;
  wire clk_2x_en = divider == 0 || divider == 8'd25;

  always @(posedge clk) begin
    divider <= divider - 1;

    if (divider == 0) begin
      divider <= 8'd50;
    end
  end

  cpu_6s46 cpu_uut (
      .clk(clk),
      .clk_en(clk_en),
      .clk_2x_en(clk_2x_en),

      .reset_n(reset_n),

      .input_k0(4'h7),
      .input_k1(4'h0),

      .rom_addr(rom_addr),
      .rom_data(rom_data),

      .video_addr(0),
      // .video_data(video_data),

      // .buzzer(buzzer),

      // Savestates
      .ss_bus_in(0),
      .ss_bus_addr(0),
      .ss_bus_wren(0),
      .ss_bus_reset_n(0)
      // .ss_bus_out(ss_bus_out),

      // .ss_ready(ss_ready)
  );

  always begin
    // #1 clk = ~clk;
    // #1 clk = ~clk;
    // #1 clk_2x = ~clk_2x;

    // #1 clk_2x = ~clk_2x;

    #1 clk = ~clk;
    // clk_2x = ~clk_2x;
  end

  always @(posedge clk) begin
    // ROM access
    rom_data <= rom[rom_addr][11:0];
  end

  // initial begin
  //   reg [12:0] pc;

  //   #8;

  //   reset_n = 1;
  //   forever begin
  //     @(posedge clk iff cpu_uut.core.microcode.is_last_cycle_step);
  //   end
  // end

  initial begin
    int fd;
    int ft;
    fd = $fopen("log.txt", "w");
    ft = $fopen("timestamps.txt", "w");

    // Actually zero values for better logging
    cpu_uut.core.regs.sp = 0;
    cpu_uut.core.regs.x = 0;
    cpu_uut.core.regs.y = 0;
    cpu_uut.core.regs.a = 0;
    cpu_uut.core.regs.b = 0;
    cpu_uut.core.regs.zero = 0;
    cpu_uut.core.regs.carry = 0;
    cpu_uut.core.regs.decimal = 0;
    cpu_uut.core.regs.interrupt = 0;

    fork
      begin : core_iter
        reg [12:0] pc;

        #8;

        reset_n = 1;
        forever begin
          @(posedge clk iff clk_en && cpu_uut.core.microcode.is_last_cycle_step);

          #1;

          pc = cpu_uut.core.regs.pc;

          if (~cpu_uut.core.microcode.performing_interrupt) begin
            // Only print if not in interrupt
            $fwrite(
                fd,
                "0x%3H - %12b - PC = 0x%4H, SP = 0x%2H, NP = 0x%2H, X = 0x%3H, Y = 0x%3H, A = 0x%1H, B = 0x%1H, F = 0x%1H\n",
                rom[pc], rom[pc], pc, cpu_uut.core.regs.sp, cpu_uut.core.regs.np,
                cpu_uut.core.regs.x, cpu_uut.core.regs.y, cpu_uut.core.regs.a, cpu_uut.core.regs.b,
                cpu_uut.core.regs.flags_in);

            $fwrite(ft, "%t\n", $time());
          end
        end
      end

      begin : watchdog
        // Run for ~5s
        #(131072 * 25 * 1);
        $fclose(fd);
        $fclose(ft);
      end
    join_any
  end
endmodule
