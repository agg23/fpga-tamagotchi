`include "vunit_defines.svh"

module extra_tb;
  bench bench();

  `TEST_SUITE begin
    `TEST_CASE("HALT should change nothing") begin
      bench.initialize(12'hFF8); // HALT

      bench.run_until_halt();
      #1;
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);
    end

    `TEST_CASE("SLP should change nothing") begin
      bench.initialize(12'hFF9); // SLP

      bench.run_until_halt();
      #1;
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);
    end

    `TEST_CASE("NOP5 should change nothing") begin
      bench.initialize(12'hFFB); // NOP5

      bench.run_until_complete();
      #1;
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);
      bench.assert_cycle_length(5);
    end

    `TEST_CASE("NOP7 should change nothing") begin
      bench.initialize(12'hFFF); // NOP7

      bench.run_until_complete();
      #1;
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);
      bench.assert_cycle_length(7);
    end
  end;

  // The watchdog macro is optional, but recommended. If present, it
  // must not be placed inside any initial or always-block.
  `WATCHDOG(1ns);
endmodule
