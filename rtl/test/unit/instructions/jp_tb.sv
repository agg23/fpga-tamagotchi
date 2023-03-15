`include "vunit_defines.svh"

module jp_tb;
  bench bench();

  `TEST_SUITE begin
    `TEST_CASE("JP should set PC") begin
      bench.initialize(12'h023); // JP 0x23

      bench.run_until_final_stage_fetch();
      #1;
      bench.assert_expected(13'h0123, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);

      bench.run_until_complete();
      #1;
      bench.assert_cycle_length(5);
    end

    `TEST_CASE("JP should use NBP + NPP") begin
      bench.initialize(12'h045); // JP 0x45
      bench.cpu_uut.core.regs.np = 5'h12;

      bench.run_until_final_stage_fetch();
      #1;
      bench.assert_expected(13'h1245, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);

      bench.run_until_complete();
      #1;
      bench.assert_cycle_length(5);
    end

    `TEST_CASE("JPBA should set PC") begin
      bench.initialize(12'hFE8); // JPBA
      bench.cpu_uut.core.regs.a = 4'h4;
      bench.cpu_uut.core.regs.b = 4'hB;
      bench.update_prevs();

      bench.run_until_final_stage_fetch();
      #1;
      bench.assert_expected(13'h01B4, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);

      bench.run_until_complete();
      #1;
      bench.assert_cycle_length(5);
    end

    `TEST_CASE("JPBA should use NBP + NPP") begin
      bench.initialize(12'hFE8); // JPBA
      bench.cpu_uut.core.regs.a = 4'h4;
      bench.cpu_uut.core.regs.b = 4'hB;
      bench.cpu_uut.core.regs.np = 5'h15;
      bench.update_prevs();

      bench.run_until_final_stage_fetch();
      #1;
      bench.assert_expected(13'h15B4, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);

      bench.run_until_complete();
      #1;
      bench.assert_cycle_length(5);
    end
  end;

  // The watchdog macro is optional, but recommended. If present, it
  // must not be placed inside any initial or always-block.
  `WATCHDOG(1ns);
endmodule
