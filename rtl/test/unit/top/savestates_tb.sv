`include "vunit_defines.svh"

module savestates_tb;
  bench bench();

  `TEST_SUITE begin
    `TEST_CASE_SETUP begin
      bench.initialize();
    end

    `TEST_CASE("Registers should initalize to expected defaults") begin
      bench.rom_data = 12'hFFF; // NOP7

      // Reload SS buffers with default values
      bench.ss_bus_reset_n = 0;
      // Reinitialize all process blocks
      bench.reset_n = 0;

      // Wait one cycle
      #4;

      // Release reset
      bench.ss_bus_reset_n = 1;
      bench.reset_n = 1;

      #1;

      bench.assert_expected(13'h0100, 4'h0, 4'h0, 12'h0, 12'h0, 8'h0);
      bench.assert_np(5'h01);
      bench.assert_interrupt(0);
      bench.assert_decimal(0);
      bench.assert_zero(0);
      bench.assert_carry(0);
    end

    `TEST_CASE("Registers should be set by SS addresses 0x0 and 0x1") begin
      bench.rom_data = 12'hFFF; // NOP7

      // Reinitialize all process blocks
      bench.reset_n = 0;

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
      bench.rom_data = 12'hFFF; // NOP7
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

      #4;
      // {2'b0, np, pc, a, b, interrupt, decimal, zero, carry}
      bench.assert_ss_bus_out({2'b0, 5'h0E, 13'h1432, 4'h0, 4'h1, 1'b0, 1'b1, 1'b1, 1'b0});
      bench.ss_bus_addr = 8'h1;

      #4;
      // {x, y, sp}
      bench.assert_ss_bus_out({12'h271, 12'hAB3, 8'h49});
    end

    `TEST_CASE("Clock timer data should be set by SS address 0x2") begin
      bench.rom_data = 12'hFFF; // NOP7

      // Reinitialize all process blocks
      bench.reset_n = 0;

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
      bench.rom_data = 12'hFFF; // NOP7
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
      bench.rom_data = 12'hFFF; // NOP7

      // Reinitialize all process blocks
      bench.reset_n = 0;

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
      bench.rom_data = 12'hFFF; // NOP7
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
      bench.rom_data = 12'hFFF; // NOP7

      // Reinitialize all process blocks
      bench.reset_n = 0;

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
      bench.rom_data = 12'hFFF; // NOP7
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

    `TEST_CASE("Interrupt clock data should be set by SS address 0x5") begin
      bench.rom_data = 12'hFFF; // NOP7

      // Reinitialize all process blocks
      bench.reset_n = 0;

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
      bench.rom_data = 12'hFFF; // NOP7
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
      bench.rom_data = 12'hFFF; // NOP7

      // Reinitialize all process blocks
      bench.reset_n = 0;

      #4;
      #1;

      // {30'b0, factor_flags}
      bench.ss_write(8'h6, {30'b0, 2'h2});

      #4;
      `CHECK_EQUAL(bench.cpu_uut.input_lines.factor_flags, 2'h2);
    end

    `TEST_CASE("Input interrupt factor should be read by SS address 0x6") begin
      bench.rom_data = 12'hFFF; // NOP7
      bench.ss_bus_addr = 8'h6;

      #1;

      bench.cpu_uut.input_lines.factor_flags = 2'h3;

      #3;

      // {30'b0, factor_flags}
      bench.assert_ss_bus_out({30'b0, 2'h3});
    end
  end;

  // The watchdog macro is optional, but recommended. If present, it
  // must not be placed inside any initial or always-block.
  `WATCHDOG(1ns);
endmodule
