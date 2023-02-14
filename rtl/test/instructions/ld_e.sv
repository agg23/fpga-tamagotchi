`include "vunit_defines.svh"

module ld_e_tb;
  bench bench();

  `TEST_SUITE begin
    `TEST_CASE_SETUP begin
      bench.initialize();
    end

    `TEST_CASE("LD X e should load 8 bit immediate") begin
      bench.rom_data = 12'hB69; // LD X, e

      bench.run_until_complete();
      #1;
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, 12'h269, bench.prev_y, bench.prev_sp);
      bench.assert_cycle_length(5);
    end

    `TEST_CASE("LD Y e should load 8 bit immediate") begin
      bench.rom_data = 12'h8F3; // LD Y, e

      bench.run_until_complete();
      #1;
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, 12'h3F3, bench.prev_sp);
      bench.assert_cycle_length(5);
    end
  end;

  // The watchdog macro is optional, but recommended. If present, it
  // must not be placed inside any initial or always-block.
  `WATCHDOG(1ns);
endmodule
