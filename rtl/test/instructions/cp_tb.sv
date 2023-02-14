`include "vunit_defines.svh"

module cp_tb;
  bench bench();

  `TEST_SUITE begin
    `TEST_CASE_SETUP begin
      bench.initialize();
    end

    `TEST_CASE("CP XH i should set flags") begin
      bench.rom_data = 12'hA4F; // CP XH, i

      bench.run_until_complete();
      #1;

      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);
      bench.assert_cycle_length(7);

      // F > 2
      bench.assert_carry(1);
      bench.assert_zero(0);
    end

    `TEST_CASE("CP XL i should set flags") begin
      bench.rom_data = 12'hA52; // CP XL, i

      bench.run_until_complete();
      #1;

      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);
      bench.assert_cycle_length(7);

      // 2 == 2
      bench.assert_carry(0);
      bench.assert_zero(1);
    end

    `TEST_CASE("CP YH i should set flags") begin
      bench.rom_data = 12'hA62; // CP YH, i

      bench.run_until_complete();
      #1;

      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);
      bench.assert_cycle_length(7);

      // 2 < 3
      bench.assert_carry(0);
      bench.assert_zero(0);
    end

    `TEST_CASE("CP YL i should set flags") begin
      bench.rom_data = 12'hA74; // CP YH, i

      bench.run_until_complete();
      #1;

      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);
      bench.assert_cycle_length(7);

      // 4 > 3
      bench.assert_carry(1);
      bench.assert_zero(0);
    end
  end;

  // The watchdog macro is optional, but recommended. If present, it
  // must not be placed inside any initial or always-block.
  `WATCHDOG(1ns);
endmodule
