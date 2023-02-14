`include "vunit_defines.svh"

module retd_tb;
  bench bench();

  `TEST_SUITE begin
    `TEST_CASE_SETUP begin
      bench.initialize();
    end

    `TEST_CASE("RETD should set PC and increment X twice") begin
      bench.rom_data = 12'h1FC; // RETD 0xFC
      bench.cpu_uut.regs.x = 12'h4F1;
      bench.cpu_uut.regs.sp = 8'h44;
      bench.ram[8'h44] = 4'hD;  // PCSL
      bench.ram[8'h45] = 4'h4;  // PCSL
      bench.ram[8'h46] = 4'h7;  // PCP

      bench.run_until_final_stage_fetch();
      #1;
      bench.assert_expected(13'h074D, bench.prev_a, bench.prev_b, 12'hXXX, bench.prev_y, 8'h47);

      bench.run_until_complete();
      #1;
      bench.assert_cycle_length(12);
      bench.assert_ram(12'h4F1, 4'hC); // Lower nibble of immediate
      bench.assert_ram(12'h4F2, 4'hF); // Upper nibble of immediate

      bench.assert_x(12'h4F3);
    end
  end;

  // The watchdog macro is optional, but recommended. If present, it
  // must not be placed inside any initial or always-block.
  `WATCHDOG(1ns);
endmodule