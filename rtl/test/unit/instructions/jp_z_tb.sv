`include "vunit_defines.svh"

module jp_z_tb;
  core_bench bench();

  `TEST_SUITE begin
    `TEST_CASE_SETUP begin
      bench.initialize();
    end

    `TEST_CASE("JP Z should not jump when zero isn't set") begin
      bench.rom_data = 12'h603; // JP Z 0x03

      bench.run_until_final_stage_fetch();
      #1;
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);

      bench.run_until_complete();
      #1;
      bench.assert_cycle_length(5);
    end

    `TEST_CASE("JP Z should jump when zero is set") begin
      bench.rom_data = 12'h603; // JP Z 0x03
      bench.cpu_uut.regs.zero = 1;
      bench.cpu_uut.regs.np = 5'h14;

      bench.run_until_final_stage_fetch();
      #1;
      bench.assert_expected(13'h1403, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);

      bench.run_until_complete();
      #1;
      bench.assert_cycle_length(5);
    end

    `TEST_CASE("JP NZ should jump when zero isn't set") begin
      bench.rom_data = 12'h787; // JP NZ 0x87

      bench.run_until_final_stage_fetch();
      #1;
      bench.assert_expected(13'h0187, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);

      bench.run_until_complete();
      #1;
      bench.assert_cycle_length(5);
    end

    `TEST_CASE("JP NZ should not jump when zero is set") begin
      bench.rom_data = 12'h787; // JP NZ 0x87
      bench.cpu_uut.regs.zero = 1;
      bench.cpu_uut.regs.np = 5'h14;

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
