`include "vunit_defines.svh"

module adc_tb;
  bench bench();

  `TEST_SUITE begin
    `TEST_CASE_SETUP begin
      bench.initialize();
    end

    `TEST_CASE("ADC XH i should load with 4 bit immediate") begin
      bench.rom_data = 12'hA0F; // ADC XH, i

      bench.run_until_complete();
      #1;

      // 2 + F = 1 + c
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, 12'h212, bench.prev_y, bench.prev_sp);
      bench.assert_cycle_length(7);
      bench.assert_carry(1);
      bench.assert_zero(0);
    end

    `TEST_CASE("ADC XL i should load with 4 bit immediate") begin
      bench.rom_data = 12'hA1E; // ADC XL, i

      bench.run_until_complete();
      #1;

      // 2 + E = 0 + c
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, 12'h220, bench.prev_y, bench.prev_sp);
      bench.assert_cycle_length(7);
      bench.assert_carry(1);
      bench.assert_zero(1);
    end

    `TEST_CASE("ADC YH i should load with 4 bit immediate") begin
      bench.rom_data = 12'hA27; // ADC YH, i

      bench.run_until_complete();
      #1;

      // 3 + 7 = A
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, 12'h3A3, bench.prev_sp);
      bench.assert_cycle_length(7);
      bench.assert_carry(0);
      bench.assert_zero(0);
    end

    `TEST_CASE("ADC YL i should load with 4 bit immediate") begin
      bench.rom_data = 12'hA3D; // ADC YL, i

      bench.run_until_complete();
      #1;

      // 3 + D = 0 + c
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, 12'h330, bench.prev_sp);
      bench.assert_cycle_length(7);
      bench.assert_carry(1);
      bench.assert_zero(1);
    end
  end;

  // The watchdog macro is optional, but recommended. If present, it
  // must not be placed inside any initial or always-block.
  `WATCHDOG(1ns);
endmodule
