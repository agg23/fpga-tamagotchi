`include "vunit_defines.svh"

module jp_c_tb;
  core_bench bench();

  `TEST_SUITE begin
    `TEST_CASE("JP C should not jump when carry isn't set") begin
      bench.initialize(12'h2CD); // JP C, 0xCD

      bench.run_until_final_stage_fetch();
      #1;
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);

      bench.run_until_complete();
      #1;
      bench.assert_cycle_length(5);
    end

    `TEST_CASE("JP C should jump when carry is set") begin
      bench.initialize(12'h2CD); // JP C, 0xCD
      bench.cpu_uut.regs.carry = 1;

      bench.run_until_final_stage_fetch();
      #1;
      bench.assert_expected(13'h01CD, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);

      bench.run_until_complete();
      #1;
      bench.assert_cycle_length(5);
    end

    `TEST_CASE("JP NC should jump when carry isn't set") begin
      bench.initialize(12'h3F1); // JP NC, 0xF1

      bench.run_until_final_stage_fetch();
      #1;
      bench.assert_expected(13'h01F1, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);

      bench.run_until_complete();
      #1;
      bench.assert_cycle_length(5);
    end

    `TEST_CASE("JP NC should not jump when carry is set") begin
      bench.initialize(12'h3F1); // JP NC, 0xF1
      bench.cpu_uut.regs.carry = 1;

      bench.run_until_final_stage_fetch();
      #1;
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);

      bench.run_until_complete();
      #1;
      bench.assert_cycle_length(5);
    end
  end;

  // The watchdog macro is optional, but recommended. If present, it
  // must not be placed inside any initial or always-block.
  `WATCHDOG(1ns);
endmodule
