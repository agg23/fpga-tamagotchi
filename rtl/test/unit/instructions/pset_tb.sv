`include "vunit_defines.svh"

module pset_tb;
  core_bench bench();

  `TEST_SUITE begin
    `TEST_CASE_SETUP begin
      bench.initialize();
    end

    `TEST_CASE("PSET should set NPP") begin
      bench.rom_data = 12'hE4F; // PSET p

      bench.run_until_complete();
      #1;
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);
      bench.assert_cycle_length(5);

      bench.assert_np(5'h0F);
    end

    `TEST_CASE("PSET should set NBP") begin
      bench.rom_data = 12'hE54; // PSET p

      bench.run_until_complete();
      #1;
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);
      bench.assert_cycle_length(5);

      bench.assert_np(5'h14);
    end

    `TEST_CASE("NBP and NPP should be reset after non-PSET") begin
      bench.rom_data = 12'hFFB; // NOP5

      bench.cpu_uut.regs.np = 5'h1A;

      bench.run_until_complete();

      // Set up next instruction
      bench.rom_data = 12'h0A5; // JP 0xA5
      #1;
      bench.assert_np(5'h01); // Default starting NP

      bench.run_until_complete();
      #1;
      bench.assert_expected(13'h01A5, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);
      bench.assert_np(5'h01);
    end
  end;

  // The watchdog macro is optional, but recommended. If present, it
  // must not be placed inside any initial or always-block.
  `WATCHDOG(1ns);
endmodule
