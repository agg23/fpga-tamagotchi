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

      #4;
      #1;
      test_swl_1hz();
      test_swl_1hz();
      test_swl_1hz();
    end
  end;

  // The watchdog macro is optional, but recommended. If present, it
  // must not be placed inside any initial or always-block.
  `WATCHDOG(500ns);
endmodule
