`include "vunit_defines.svh"

module stopwatch_tb;
  bench bench();

  task test_swl_1hz();
    // 26 26
    test_swl_pattern2(1);
    test_swl_pattern2(2);

    // 25 25
    test_swl_pattern1(3);
    test_swl_pattern1(4);

    // 26 26
    test_swl_pattern2(5);
    test_swl_pattern2(6);

    // 25 25
    test_swl_pattern1(7);
    test_swl_pattern1(8);

    // 26 26
    test_swl_pattern2(9);
    test_swl_pattern2(0);
  endtask

  task test_swl_pattern1(reg [3:0] expected_swh);
    // 3/256
    // 256hz is 128 cycles
    // 128 * 3 * 4 + 4
    #1536;
    `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_swl, 4'h1);

    // 2/256
    #1024;
    `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_swl, 4'h2);

    // 3/256
    #1536;
    `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_swl, 4'h3);

    // 2/256
    #1024;
    `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_swl, 4'h4);

    // 3/256
    #1536;
    `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_swl, 4'h5);

    // 2/256
    #1024;
    `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_swl, 4'h6);

    // 3/256
    #1536;
    `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_swl, 4'h7);

    // 2/256
    #1024;
    `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_swl, 4'h8);

    // 3/256
    #1536;
    `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_swl, 4'h9);

    // 2/256
    #1024;
    `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_swl, 4'h0);
    `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_swh, expected_swh);
  endtask

  task test_swl_pattern2(reg [3:0] expected_swh);
    // 3/256
    // 256hz is 128 cycles
    // 128 * 3 * 4 + 4
    #1536;
    `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_swl, 4'h1);

    // 3/256
    #1536;
    `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_swl, 4'h2);

    // 3/256
    #1536;
    `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_swl, 4'h3);

    // 2/256
    #1024;
    `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_swl, 4'h4);

    // 3/256
    #1536;
    `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_swl, 4'h5);

    // 2/256
    #1024;
    `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_swl, 4'h6);

    // 3/256
    #1536;
    `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_swl, 4'h7);

    // 2/256
    #1024;
    `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_swl, 4'h8);

    // 3/256
    #1536;
    `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_swl, 4'h9);

    // 2/256
    #1024;
    `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_swl, 4'h0);
    `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_swh, expected_swh);
  endtask

  `TEST_SUITE begin
    `TEST_CASE_SETUP begin
      bench.initialize();
    end

    `TEST_CASE("SWL counter should pass timing") begin
      bench.rom_data = 12'hFFF; // NOP7
      bench.cpu_uut.enable_stopwatch = 1;

      #4;
      #1;
      test_swl_1hz();
      test_swl_1hz();
      test_swl_1hz();
    end

    `TEST_CASE("Reading from 0xF22 should return 1/100 sec data") begin
      bench.rom_data = 12'hFFF; // NOP7
      bench.cpu_uut.enable_stopwatch = 1;

      // 17/100: 1/256 * (26 + 19): 23040 + 4ps
      #23044;

      bench.run_until_complete();
      bench.cpu_uut.core.regs.x = 12'hF22;
      bench.rom_data = 12'hEC2; // LD A, MX

      bench.run_until_complete();
      #1;
      bench.assert_a(4'b0111);
    end

    `TEST_CASE("Reading from 0xF23 should return 1/10 sec data") begin
      bench.rom_data = 12'hFFF; // NOP7
      bench.cpu_uut.enable_stopwatch = 1;

      // 62/100: 1/256 * (26 + 26 + 25 + 25 + 26 + 26 + 5): 81408 + 4ps
      #81412;

      bench.run_until_complete();
      bench.cpu_uut.core.regs.x = 12'hF23;
      bench.rom_data = 12'hEC2; // LD A, MX

      bench.run_until_complete();
      #1;
      bench.assert_a(4'b0110);
    end

    `TEST_CASE("Stopwatch should only start once 0xF77 bit 0 is set") begin
      bench.rom_data = 12'hFFF; // NOP7

      // 17/100: 1/256 * (26 + 19): 23040 + 4ps
      #23044;

      `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_swl, 4'h0);
      `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_swh, 4'h0);

      bench.run_until_complete();
      bench.cpu_uut.core.regs.a = 4'b0011;
      bench.cpu_uut.core.regs.x = 12'hF77;
      bench.rom_data = 12'hEC8; // LD MX, A

      bench.run_until_complete();
      bench.rom_data = 12'hFFF; // NOP7
      #1;
      `CHECK_EQUAL(bench.cpu_uut.enable_stopwatch, 1);

      // 17/100: 1/256 * (26 + 19): 23040 + 4ps
      #23044;

      `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_swl, 4'h7);
      `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_swh, 4'h1);
    end

    `TEST_CASE("Stopwatch should pause on 0xF77 bit 0 clear and resume on bit 0 set") begin
      bench.rom_data = 12'hFFF; // NOP7
      bench.cpu_uut.enable_stopwatch = 1;

      // 17/100: 1/256 * (26 + 19): 23040 + 4ps
      #23044;
      #1;

      `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_swl, 4'h7);
      `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_swh, 4'h1);

      // Disable stopwatch
      bench.run_until_complete();
      bench.cpu_uut.core.regs.a = 4'b0000;
      bench.cpu_uut.core.regs.x = 12'hF77;
      bench.rom_data = 12'hEC8; // LD MX, A

      bench.run_until_complete();
      bench.rom_data = 12'hFFF; // NOP7

      #1;
      `CHECK_EQUAL(bench.cpu_uut.enable_stopwatch, 0);

      // 17/100: 1/256 * (26 + 19): 23040 + 4ps
      #23044;
      #1;

      `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_swl, 4'h7);
      `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_swh, 4'h1);

      // Start stopwatch
      bench.run_until_complete();
      bench.cpu_uut.core.regs.a = 4'b0001;
      bench.cpu_uut.core.regs.x = 12'hF77;
      bench.rom_data = 12'hEC8; // LD MX, A

      bench.run_until_complete();
      bench.rom_data = 12'hFFF; // NOP7

      #1;
      `CHECK_EQUAL(bench.cpu_uut.enable_stopwatch, 1);

      // 17/100: 1/256 * (7 + 25 + 10): 23040 + 4ps
      #21504;

      // 17 + 17 = 34
      `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_swl, 4'h4);
      `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_swh, 4'h3);
    end

    `TEST_CASE("Stopwatch should reset on 0xF77 bit 1 set") begin
      bench.rom_data = 12'hFFF; // NOP7
      bench.cpu_uut.enable_stopwatch = 1;
      bench.cpu_uut.timers.stopwatch.counter_swl = 4'h9;
      bench.cpu_uut.timers.stopwatch.counter_swh = 4'h2;

      // Random duration so that it's not right at the beginning of a tick
      #400;

      bench.run_until_complete();
      bench.cpu_uut.core.regs.a = 4'b0011;
      bench.cpu_uut.core.regs.x = 12'hF77;
      bench.rom_data = 12'hEC8; // LD MX, A

      bench.run_until_complete();
      bench.rom_data = 12'hFFF; // NOP7

      #10;

      `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_swl, 4'h0);
      `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_swh, 4'h0);

      // 17/100: 1/256 * (26 + 19): 23040 + 4ps
      #23044;
      #1;

      `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_swl, 4'h7);
      `CHECK_EQUAL(bench.cpu_uut.timers.stopwatch.counter_swh, 4'h1);
    end

    `TEST_CASE("Reading 0xF01 should get factor flags and clear them") begin
      bench.rom_data = 12'hFFF; // NOP7
      bench.cpu_uut.enable_stopwatch = 1;

      // 17/100: 1/256 * (26 + 19): 23040 + 4ps
      #23044;
      #1;

      `CHECK_EQUAL(bench.cpu_uut.stopwatch_factor, 4'b01);

      bench.run_until_complete();
      bench.cpu_uut.core.regs.x = 12'hF01;
      bench.rom_data = 12'hEC2; // LD A, MX

      bench.run_until_complete();
      bench.rom_data = 12'hFFF; // NOP7
      #1;
      bench.assert_a(4'h1);
      `CHECK_EQUAL(bench.cpu_uut.stopwatch_factor, 4'b00);

      // 256 - (26 + 19)
      #108036;
      `CHECK_EQUAL(bench.cpu_uut.stopwatch_factor, 4'b11);
    end

    `TEST_CASE("Interrupt factor AND with mask should produce interrupts") begin
      bench.rom_data = 12'hFFF; // NOP7
      bench.cpu_uut.core.regs.interrupt = 1;
      bench.cpu_uut.enable_stopwatch = 1;
      bench.cpu_uut.stopwatch_mask = 2'b01;

      // 10/100: 26/256: 13312 + 4ps
      #13316;
      #1;

      `CHECK_EQUAL(bench.cpu_uut.stopwatch_factor, 4'b01);

      bench.run_until_complete();
      #1;
      // Interrupt should begin processing
      `CHECK_EQUAL(bench.cpu_uut.core.microcode.performing_interrupt, 1);

      bench.run_until_complete();
      #1;
      bench.assert_pc(13'h0104);
    end

    `TEST_CASE("Interrupts should not be produced if factor AND mask is 0") begin
      bench.rom_data = 12'hFFF; // NOP7
      bench.cpu_uut.core.regs.interrupt = 1;
      bench.cpu_uut.enable_stopwatch = 1;
      bench.cpu_uut.stopwatch_mask = 2'b10;

      // 10/100: 26/256: 13312 + 4ps
      #13316;
      #1;

      `CHECK_EQUAL(bench.cpu_uut.stopwatch_factor, 4'b01);

      bench.run_until_complete();
      #1;
      // Interrupt should NOT begin processing
      `CHECK_EQUAL(bench.cpu_uut.core.microcode.performing_interrupt, 0);

      // 90/100: (256-26)/256: 117760
      #117760;

      `CHECK_EQUAL(bench.cpu_uut.stopwatch_factor, 4'b11);

      bench.run_until_complete();
      #1;
      // Interrupt should begin processing
      `CHECK_EQUAL(bench.cpu_uut.core.microcode.performing_interrupt, 1);

      bench.run_until_complete();
      #1;
      bench.assert_pc(13'h0104);
    end

    `TEST_CASE("Reading/writing from 0xF11 should read/write mask settings") begin
      bench.rom_data = 12'hEC8; // LD MX, A
      bench.cpu_uut.core.regs.a = 4'h6;
      bench.cpu_uut.core.regs.x = 12'hF11;

      bench.run_until_complete();
      bench.rom_data = 12'hEC6; // LD B, MX
      #1;
      `CHECK_EQUAL(bench.cpu_uut.stopwatch_mask, 2'b10);

      bench.run_until_complete();
      #1;
      bench.assert_b(4'h2);
    end
  end;

  // The watchdog macro is optional, but recommended. If present, it
  // must not be placed inside any initial or always-block.
  `WATCHDOG(500ns);
endmodule
