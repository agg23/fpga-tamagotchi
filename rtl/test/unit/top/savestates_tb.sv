`include "vunit_defines.svh"

module savestates_tb;
  bench bench();

  `TEST_SUITE begin
    `TEST_CASE("Registers should initalize to expected defaults") begin
      bench.initialize(12'hFFF); // NOP7

      // Reload SS buffers with default values
      bench.ss_bus_reset = 1;
      // Reinitialize all process blocks
      bench.reset = 1;

      // Wait one cycle
      #4;

      // Release reset
      bench.ss_bus_reset = 0;
      bench.reset = 0;

      #1;

      bench.assert_expected(13'h0100, 4'h0, 4'h0, 12'h0, 12'h0, 8'h0);
      bench.assert_np(5'h01);
      bench.assert_interrupt(0);
      bench.assert_decimal(0);
      bench.assert_zero(0);
      bench.assert_carry(0);
    end

    `TEST_CASE("Registers should be set by SS addresses 0x0 and 0x1") begin
      bench.initialize(12'hFFF); // NOP7

      // Reinitialize all process blocks
      bench.reset = 1;

      #4;
      #1;

      // {2'b0, np, pc, a, b, interrupt, decimal, zero, carry}
      bench.ss_write(0, {2'b0, 5'h15, 13'h0F71, 4'h4, 4'hC, 1'b1, 1'b0, 1'b1, 1'b1});
      // {x, y, sp}
      bench.ss_write(1, {12'h325, 12'h9D1, 8'hF3});

      #4;
      bench.assert_expected(13'h0F71, 4'h4, 4'hC, 12'h325, 12'h9D1, 8'hF3);
      bench.assert_np(5'h15);
      bench.assert_interrupt(1);
      bench.assert_decimal(0);
      bench.assert_zero(1);
      bench.assert_carry(1);
    end

    `TEST_CASE("Registers should be read by SS addresses 0x0 and 0x1") begin
      bench.initialize(12'hFFF); // NOP7

      #1;
      bench.ss_bus_addr = 0;

      bench.cpu_uut.core.regs.pc = 13'h1432;
      bench.cpu_uut.core.regs.np = 5'h0E;

      bench.cpu_uut.core.regs.a = 4'h0;
      bench.cpu_uut.core.regs.b = 4'h1;

      bench.cpu_uut.core.regs.x = 12'h271;
      bench.cpu_uut.core.regs.y = 12'hAB3;

      bench.cpu_uut.core.regs.sp = 8'h49;

      bench.cpu_uut.core.regs.zero = 1;
      bench.cpu_uut.core.regs.carry = 0;
      bench.cpu_uut.core.regs.decimal = 1;
      bench.cpu_uut.core.regs.interrupt = 0;

      #3;
      // {2'b0, np, pc, a, b, interrupt, decimal, zero, carry}
      bench.assert_ss_bus_out({2'b0, 5'h0E, 13'h1432, 4'h0, 4'h1, 1'b0, 1'b1, 1'b1, 1'b0});
      bench.ss_bus_addr = 8'h1;

      #4;
      // {x, y, sp}
      bench.assert_ss_bus_out({12'h271, 12'hAB3, 8'h49});
    end

    `TEST_CASE("Clock timer data should be set by SS address 0x2") begin
      bench.initialize(12'hFFF); // NOP7

      // Reinitialize all process blocks
      bench.reset = 1;

      #4;
      #1;

      // {16'b0, timer_256_tick, divider, counter_256}
      bench.ss_write(8'h2, {16'b0, 1'b1, 7'h5A, 8'hD4});

      #4;
      `CHECK_EQUAL(bench.cpu_uut.timers.clock.timer_256_tick, 1);
      `CHECK_EQUAL(bench.cpu_uut.timers.clock.divider, 7'h5A);
      `CHECK_EQUAL(bench.cpu_uut.timers.clock.counter_256, 8'hD4);
    end

    `TEST_CASE("Clock timer data should be read by SS address 0x2") begin
      bench.initialize(12'hFFF); // NOP7
      #3;
      bench.ss_bus_addr = 8'h2;

      #1;

      bench.cpu_uut.timers.clock.timer_256_tick = 1;
      bench.cpu_uut.timers.clock.divider = 7'h5A;
      bench.cpu_uut.timers.clock.counter_256 = 8'hD4;

      #3;

      // {16'b0, timer_256_tick, divider, counter_256}
      bench.assert_ss_bus_out({16'b0, 1'b1, 7'h5A, 8'hD4});
    end

    `TEST_CASE("Stopwatch data should be set by SS address 0x3") begin
      bench.initialize(12'hFFF); // NOP7

      // Reinitialize all process blocks
      bench.reset = 1;

      #4;
      #1;

      // {18'b0, factor_flags, counter_100hz, counter_swh, counter_swl}
      bench.ss_write(8'h3, {18'b0, 2'h3, 4'h5, 4'hF, 4'hA});

      #4;
      `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.factor_flags, 2'h3);
      `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_100hz, 4'h5);
      `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_swh, 4'hF);
      `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_swl, 4'hA);
    end

    `TEST_CASE("Stopwatch data should be read by SS address 0x3") begin
      bench.initialize(12'hFFF); // NOP7
      #3;
      bench.ss_bus_addr = 8'h3;

      #1;

      bench.cpu_uut.timers.stopwatch.factor_flags = 2'h3;
      bench.cpu_uut.timers.stopwatch.counter_100hz = 4'h5;
      bench.cpu_uut.timers.stopwatch.counter_swh = 4'hF;
      bench.cpu_uut.timers.stopwatch.counter_swl = 4'hA;

      #3;

      // {18'b0, factor_flags, counter_100hz, counter_swh, counter_swl}
      bench.assert_ss_bus_out({18'b0, 2'h3, 4'h5, 4'hF, 4'hA});
    end

    `TEST_CASE("Prog timer data should be set by SS address 0x4") begin
      bench.initialize(12'hFFF); // NOP7

      // Reinitialize all process blocks
      bench.reset = 1;

      #4;
      #1;

      // {16'b0, factor_flags, downcounter, divider_8khz, counter_8khz}
      bench.ss_write(8'h4, {16'b0, 1'b1, 8'hEA, 1'b1, 6'h25});

      #4;
      `CHECK_EQUAL(bench.cpu_uut.timers.prog_timer.factor_flags, 1'b1);
      `CHECK_EQUAL(bench.cpu_uut.timers.prog_timer.downcounter, 8'hEA);
      `CHECK_EQUAL(bench.cpu_uut.timers.prog_timer.divider_8khz, 1'b1);
      `CHECK_EQUAL(bench.cpu_uut.timers.prog_timer.counter_8khz, 6'h25);
    end

    `TEST_CASE("Prog timer data should be read by SS address 0x4") begin
      bench.initialize(12'hFFF); // NOP7
      #3;
      bench.ss_bus_addr = 8'h4;

      #1;

      bench.cpu_uut.timers.prog_timer.factor_flags = 1'b1;
      bench.cpu_uut.timers.prog_timer.downcounter = 8'hEA;
      bench.cpu_uut.timers.prog_timer.divider_8khz = 1'b1;
      bench.cpu_uut.timers.prog_timer.counter_8khz = 6'h25;

      #3;

      // {18'b0, factor_flags, counter_100hz, counter_swh, counter_swl}
      bench.assert_ss_bus_out({16'b0, 1'b1, 8'hEA, 1'b1, 6'h25});
    end

    `TEST_CASE("Prog timer data should initalize to expected defaults") begin
      bench.initialize(12'hFFF); // NOP7

      // Reload SS buffers with default values
      bench.ss_bus_reset = 1;
      // Reinitialize all process blocks
      bench.reset = 1;

      // Wait one cycle
      #4;

      // Release reset
      bench.ss_bus_reset = 0;
      bench.reset = 0;

      #1;

      `CHECK_EQUAL(bench.cpu_uut.timers.prog_timer.downcounter, 8'hFF);
    end

    `TEST_CASE("Interrupt clock data should be set by SS address 0x5") begin
      bench.initialize(12'hFFF); // NOP7

      // Reinitialize all process blocks
      bench.reset = 1;

      #4;
      #1;

      // {24'b0, prev_timer_32hz, prev_timer_8hz, prev_timer_2hz, prev_timer_1hz, clock_factor}
      bench.ss_write(8'h5, {24'b0, 1'b1, 1'b0, 1'b1, 1'b1, 4'hA});

      #4;
      `CHECK_EQUAL(bench.cpu_uut.interrupt.prev_timer_32hz, 1'b1);
      `CHECK_EQUAL(bench.cpu_uut.interrupt.prev_timer_8hz, 1'b0);
      `CHECK_EQUAL(bench.cpu_uut.interrupt.prev_timer_2hz, 1'b1);
      `CHECK_EQUAL(bench.cpu_uut.interrupt.prev_timer_1hz, 1'b1);
      `CHECK_EQUAL(bench.cpu_uut.interrupt.clock_factor, 4'hA);
    end

    `TEST_CASE("Interrupt data should be read by SS address 0x5") begin
      bench.initialize(12'hFFF); // NOP7
      #3;
      bench.ss_bus_addr = 8'h5;

      #1;

      bench.cpu_uut.interrupt.prev_timer_32hz = 1'b1;
      bench.cpu_uut.interrupt.prev_timer_8hz = 1'b0;
      bench.cpu_uut.interrupt.prev_timer_2hz = 1'b1;
      bench.cpu_uut.interrupt.prev_timer_1hz = 1'b1;
      bench.cpu_uut.interrupt.clock_factor = 4'hA;

      #3;

      // {24'b0, prev_timer_32hz, prev_timer_8hz, prev_timer_2hz, prev_timer_1hz, clock_factor}
      bench.assert_ss_bus_out({24'b0, 1'b1, 1'b0, 1'b1, 1'b1, 4'hA});
    end

    `TEST_CASE("Input interrupt factor should be set by SS address 0x6") begin
      bench.initialize(12'hFFF); // NOP7

      // Reinitialize all process blocks
      bench.reset = 1;

      #4;
      #1;

      // {30'b0, factor_flags}
      bench.ss_write(8'h6, {30'b0, 2'h2});

      #4;
      `CHECK_EQUAL(bench.cpu_uut.input_lines.factor_flags, 2'h2);
    end

    `TEST_CASE("Input interrupt factor should be read by SS address 0x6") begin
      bench.initialize(12'hFFF); // NOP7
      #3;
      bench.ss_bus_addr = 8'h6;

      #1;

      bench.cpu_uut.input_lines.factor_flags = 2'h3;

      #3;

      // {30'b0, factor_flags}
      bench.assert_ss_bus_out({30'b0, 2'h3});
    end

    `TEST_CASE("CPU memmap regs should initalize to expected defaults") begin
      bench.initialize(12'hFFF); // NOP7

      // Reload SS buffers with default values
      bench.ss_bus_reset = 1;
      // Reinitialize all process blocks
      bench.reset = 1;

      // Wait one cycle
      #4;

      // Release reset
      bench.ss_bus_reset = 0;
      bench.reset = 0;

      #1;

      `CHECK_EQUAL(bench.cpu_uut.input_relation_k0, 4'hF);
      `CHECK_EQUAL(bench.cpu_uut.buzzer_output_control, 4'hF);
      `CHECK_EQUAL(bench.cpu_uut.buzzer_frequency_selection, 4'hF);
      `CHECK_EQUAL(bench.cpu_uut.lcd_control, 3'b100);
      `CHECK_EQUAL(bench.cpu_uut.lcd_contrast, 4'h8);
    end

    `TEST_CASE("CPU memmap regs set 1 should be set by SS address 0x7") begin
      bench.initialize(12'hFFF); // NOP7

      // Reinitialize all process blocks
      bench.reset = 1;

      #4;
      #1;

      // {enable_stopwatch, enable_prog_timer, prog_timer_clock_selection, prog_timer_reload, clock_mask, stopwatch_mask, prog_timer_mask, input_k0_mask, input_k1_mask, input_relation_k0}
      bench.ss_write(8'h7, {1'b1, 1'b0, 3'h5, 8'hAF, 4'h9, 2'h3, 1'b1, 4'hD, 4'hA, 4'h7});

      #4;
      `CHECK_EQUAL(bench.cpu_uut.enable_stopwatch, 1'b1);
      `CHECK_EQUAL(bench.cpu_uut.enable_prog_timer, 1'b0);
      `CHECK_EQUAL(bench.cpu_uut.prog_timer_clock_selection, 3'h5);
      `CHECK_EQUAL(bench.cpu_uut.prog_timer_reload, 8'hAF);
      `CHECK_EQUAL(bench.cpu_uut.clock_mask, 4'h9);
      `CHECK_EQUAL(bench.cpu_uut.stopwatch_mask, 2'h3);
      `CHECK_EQUAL(bench.cpu_uut.prog_timer_mask, 1'b1);
      `CHECK_EQUAL(bench.cpu_uut.input_k0_mask, 4'hD);
      `CHECK_EQUAL(bench.cpu_uut.input_k1_mask, 4'hA);
      `CHECK_EQUAL(bench.cpu_uut.input_relation_k0, 4'h7);
    end

    `TEST_CASE("CPU memmap regs set 1 should be read by SS address 0x7") begin
      bench.initialize(12'hFFF); // NOP7
      bench.ss_bus_addr = 8'h7;

      #1;

      bench.cpu_uut.enable_stopwatch = 1'b1;
      bench.cpu_uut.enable_prog_timer = 1'b0;
      bench.cpu_uut.prog_timer_clock_selection = 3'h5;
      bench.cpu_uut.prog_timer_reload = 8'hAF;
      bench.cpu_uut.clock_mask = 4'h9;
      bench.cpu_uut.stopwatch_mask = 2'h3;
      bench.cpu_uut.prog_timer_mask = 1'b1;
      bench.cpu_uut.input_k0_mask = 4'hD;
      bench.cpu_uut.input_k1_mask = 4'hA;
      bench.cpu_uut.input_relation_k0 = 4'h7;

      #3;

      // {enable_stopwatch, enable_prog_timer, prog_timer_clock_selection, prog_timer_reload, clock_mask, stopwatch_mask, prog_timer_mask, input_k0_mask, input_k1_mask, input_relation_k0}
      bench.assert_ss_bus_out({1'b1, 1'b0, 3'h5, 8'hAF, 4'h9, 2'h3, 1'b1, 4'hD, 4'hA, 4'h7});
    end

    `TEST_CASE("CPU memmap regs set 2 should be set by SS address 0x8") begin
      bench.initialize(12'hFFF); // NOP7

      // Reinitialize all process blocks
      bench.reset = 1;

      #4;
      #1;

      // {buzzer_output_control, buzzer_frequency_selection, lcd_control, svd_status, heavy_load_protection, serial_mask, serial_data, oscillation, prog_timer_clock_output, buzzer_envelope}
      bench.ss_write(8'h8, {4'hC, 4'h8, 3'h7, 3'h5, 1'b1, 1'b0, 8'hAA, 4'hB, 1'b1, 2'h2});

      #4;
      `CHECK_EQUAL(bench.cpu_uut.buzzer_output_control, 4'hC);
      `CHECK_EQUAL(bench.cpu_uut.buzzer_frequency_selection, 4'h8);
      `CHECK_EQUAL(bench.cpu_uut.lcd_control, 3'h7);
      `CHECK_EQUAL(bench.cpu_uut.svd_status, 3'h5);
      `CHECK_EQUAL(bench.cpu_uut.heavy_load_protection, 1'b1);
      `CHECK_EQUAL(bench.cpu_uut.serial_mask, 1'b0);
      `CHECK_EQUAL(bench.cpu_uut.serial_data, 8'hAA);
      `CHECK_EQUAL(bench.cpu_uut.oscillation, 4'hB);
      `CHECK_EQUAL(bench.cpu_uut.prog_timer_clock_output, 1'b1);
      `CHECK_EQUAL(bench.cpu_uut.buzzer_envelope, 2'h2);
    end

    `TEST_CASE("CPU memmap regs set 2 should be read by SS address 0x8") begin
      bench.initialize(12'hFFF); // NOP7
      bench.ss_bus_addr = 8'h8;

      #1;

      bench.cpu_uut.buzzer_output_control = 4'hC;
      bench.cpu_uut.buzzer_frequency_selection = 4'h8;
      bench.cpu_uut.lcd_control = 3'h7;
      bench.cpu_uut.svd_status = 3'h5;
      bench.cpu_uut.heavy_load_protection = 1'b1;
      bench.cpu_uut.serial_mask = 1'b0;
      bench.cpu_uut.serial_data = 8'hAA;
      bench.cpu_uut.oscillation = 4'hB;
      bench.cpu_uut.prog_timer_clock_output = 1'b1;
      bench.cpu_uut.buzzer_envelope = 2'h2;

      #3;

      // {buzzer_output_control, buzzer_frequency_selection, lcd_control, svd_status, heavy_load_protection, serial_mask, serial_data, oscillation, prog_timer_clock_output, buzzer_envelope}
      bench.assert_ss_bus_out({4'hC, 4'h8, 3'h7, 3'h5, 1'b1, 1'b0, 8'hAA, 4'hB, 1'b1, 2'h2});
    end

    `TEST_CASE("CPU memmap regs set 3 should be set by SS address 0x9") begin
      bench.initialize(12'hFFF); // NOP7

      // Reinitialize all process blocks
      bench.reset = 1;

      #4;
      #1;

      // {lcd_contrast}
      bench.ss_write(8'h9, {28'h0, 4'h9});

      #4;
      `CHECK_EQUAL(bench.cpu_uut.lcd_contrast, 4'h9);
    end

    `TEST_CASE("CPU memmap regs set 3 should be read by SS address 0x9") begin
      bench.initialize(12'hFFF); // NOP7
      bench.ss_bus_addr = 8'h9;

      #1;

      bench.cpu_uut.lcd_contrast = 4'h9;

      #3;

      // {buzzer_output_control, buzzer_frequency_selection, lcd_control, svd_status, heavy_load_protection, serial_mask, serial_data, oscillation, prog_timer_clock_output, buzzer_envelope}
      bench.assert_ss_bus_out({28'b0, 4'h9});
    end

    `TEST_CASE("CPU RAM should be set by SS addresses 0x10-0x60") begin
      int seed;
      reg [31:0] write_value;
      write_value = 0;

      bench.initialize(12'hFFF); // NOP7

      // Reinitialize all process blocks
      bench.reset = 1;

      #4;
      #1;

      seed = 2;

      for (int i = 0; i < 80; i++) begin
        for (int j = 0; j < 8; j++) begin
          seed = (1103515245 * seed + 12345) % 2147483647;
          write_value = {seed[29:26], write_value[31:4]};
        end

        // Write
        bench.ss_bus_wren = 1;
        bench.ss_bus_addr = 8'h10 + i;
        bench.ss_bus_in = write_value;

        #2;
        bench.ss_bus_wren = 0;

        #(9 * 2);
      end

      // Let last write finish
      #2;

      // Read the random values back
      seed = 2;

      for (int i = 0; i < 640; i++) begin
        seed = (1103515245 * seed + 12345) % 2147483647;

        bench.assert_ram(i, seed[29:26]);
      end
    end

    `TEST_CASE("CPU RAM should be read by SS addresses 0x10-0x60") begin
      int seed;
      reg [31:0] write_value;
      write_value = 0;

      bench.initialize(12'hFFF); // NOP7

      #1;

      seed = 1039;

      for (int i = 0; i < 640; i++) begin
        seed = (1103515245 * seed + 12345) % 2147483647;

        bench.cpu_uut.ram.memory[i] = seed[29:26];
      end

      // Read the random values back over the bus
      seed = 1039;

      for (int i = 0; i < 80; i++) begin
        for (int j = 0; j < 8; j++) begin
          seed = (1103515245 * seed + 12345) % 2147483647;
          write_value = {seed[29:26], write_value[31:4]};
        end

        // Read
        bench.ss_bus_addr = 8'h10 + i;
        bench.ss_bus_in = write_value;

        #(10 * 2);

        bench.assert_ss_bus_out(write_value);
      end
    end

    `TEST_CASE("Video RAM should be set by SS addresses 0x60-0x74") begin
      int seed;
      reg [31:0] write_value;
      write_value = 0;

      bench.initialize(12'hFFF); // NOP7

      // Reinitialize all process blocks
      bench.reset = 1;

      #4;
      #1;

      seed = 17;

      for (int i = 0; i < 20; i++) begin
        for (int j = 0; j < 8; j++) begin
          seed = (1103515245 * seed + 12345) % 2147483647;
          write_value = {seed[29:26], write_value[31:4]};
        end

        // Write
        bench.ss_bus_wren = 1;
        bench.ss_bus_addr = 8'h60 + i;
        bench.ss_bus_in = write_value;

        #2;
        bench.ss_bus_wren = 0;

        #(9 * 2);
      end

      // Let last write finish
      #2;

      // Read the random values back
      seed = 17;

      for (int i = 0; i < 160; i++) begin
        seed = (1103515245 * seed + 12345) % 2147483647;

        `CHECK_EQUAL(bench.cpu_uut.video_ram.memory[i], seed[29:26]);
      end
    end

    `TEST_CASE("Video RAM should be read by SS addresses 0x60-0x74") begin
      int seed;
      reg [31:0] write_value;
      write_value = 0;

      bench.initialize(12'hFFF); // NOP7

      #1;

      seed = 5;

      for (int i = 0; i < 160; i++) begin
        seed = (1103515245 * seed + 12345) % 2147483647;

        bench.cpu_uut.video_ram.memory[i] = seed[29:26];
      end

      // Read the random values back over the bus
      seed = 5;

      for (int i = 0; i < 20; i++) begin
        for (int j = 0; j < 8; j++) begin
          seed = (1103515245 * seed + 12345) % 2147483647;
          write_value = {seed[29:26], write_value[31:4]};
        end

        // Read
        bench.ss_bus_addr = 8'h60 + i;
        bench.ss_bus_in = write_value;

        #(10 * 2);

        bench.assert_ss_bus_out(write_value);
      end
    end

    `TEST_CASE("RAM bridge should not output when not active address") begin
      bench.initialize(12'hFFF); // NOP7

      // Reinitialize all process blocks
      bench.reset = 1;

      // Write to video RAM
      bench.ss_bus_wren = 1;
      

      // Write 8 addresses from 0x60-0x68
      for (int i = 0; i < 8; i++) begin
        bench.ss_bus_addr = 8'h60 + i;
        bench.ss_bus_in = 32'hFFFF_FF00 | i;

        #(9 * 2);
      end

      bench.reset = 0;
      bench.ss_bus_wren = 0;

      #10;

      // Read back written data
      for (int i = 0; i < 8; i++) begin
        bench.ss_bus_addr = 8'h60 + i;

        #(10 * 2);

        bench.assert_ss_bus_out(32'hFFFF_FF00 | i);
      end

      // Walk through other parts of the bus, that should be empty
      for (int i = 0; i < 8; i++) begin
        bench.ss_bus_addr = 8'h75 + i;

        #(10 * 2);

        bench.assert_ss_bus_out(0);
      end
    end
  end;

  // The watchdog macro is optional, but recommended. If present, it
  // must not be placed inside any initial or always-block.
  `WATCHDOG(50ns);
endmodule
