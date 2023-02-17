`include "vunit_defines.svh"

module call_tb;
  bench bench();

  `TEST_SUITE begin
    `TEST_CASE_SETUP begin
      bench.initialize();
    end

    `TEST_CASE("CALL s should push to stack") begin
      bench.rom_data = 12'h4AB; // CALL 0xAB

      #1;
      bench.cpu_uut.regs.pc = 13'h1234;
      bench.cpu_uut.regs.np = 5'h12;

      bench.run_until_final_stage_fetch();
      #1;
      bench.assert_pc(13'h12AB);

      bench.run_until_complete();
      #1;
      bench.assert_cycle_length(7);
      bench.assert_expected(13'h12AB, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, 8'h41);
      bench.assert_ram(12'h43, 4'h2); // PCP
      bench.assert_ram(12'h42, 4'h3); // PCSH
      bench.assert_ram(12'h41, 4'h5); // PCSL + 1
    end

    `TEST_CASE("CALL s should use PCP but not bank") begin
      bench.rom_data = 12'h444; // CALL 0x44

      #1;
      bench.cpu_uut.regs.pc = 13'h1234;
      bench.cpu_uut.regs.np = 5'h0A;

      bench.run_until_final_stage_fetch();
      #1;
      bench.assert_pc(13'h1A44);

      bench.run_until_complete();
      #1;
      bench.assert_cycle_length(7);
      bench.assert_expected(13'h1A44, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, 8'h41);
    end

    `TEST_CASE("CALZ s should jump to page 0") begin
      bench.rom_data = 12'h569; // CALZ 0x69

      #1;
      bench.cpu_uut.regs.pc = 13'h1ABC;
      bench.cpu_uut.regs.np = 5'h15;

      bench.run_until_final_stage_fetch();
      #1;
      bench.assert_pc(13'h1069);

      bench.run_until_complete();
      #1;
      bench.assert_cycle_length(7);
      bench.assert_expected(13'h1069, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, 8'h41);
      bench.assert_ram(12'h43, 4'hA); // PCP
      bench.assert_ram(12'h42, 4'hB); // PCSH
      bench.assert_ram(12'h41, 4'hD); // PCSL + 1
    end
  end;

  // The watchdog macro is optional, but recommended. If present, it
  // must not be placed inside any initial or always-block.
  `WATCHDOG(1ns);
endmodule
