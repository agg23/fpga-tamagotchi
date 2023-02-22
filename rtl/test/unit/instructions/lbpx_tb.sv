`include "vunit_defines.svh"

module lbpx_tb;
  bench bench();

  `TEST_SUITE begin
    `TEST_CASE_SETUP begin
      bench.initialize();
    end

    `TEST_CASE("LBPX MX e should load 8 bit immediate into M(X) and increment X by 2") begin
      bench.rom_data = 12'h94B; // LBPX MX, e

      bench.run_until_complete();
      #1;
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x + 2, bench.prev_y, bench.prev_sp);
      bench.assert_cycle_length(5);

      bench.assert_ram(bench.prev_x, 4'hB);
      bench.assert_ram(bench.prev_x + 1, 4'h4);
    end

  end;

  // The watchdog macro is optional, but recommended. If present, it
  // must not be placed inside any initial or always-block.
  `WATCHDOG(1ns);
endmodule
