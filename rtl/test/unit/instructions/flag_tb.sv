`include "vunit_defines.svh"

module flag_tb;
  core_bench bench();

  parameter i = 0;
  parameter p = 0;

  `TEST_SUITE begin
    `TEST_CASE_SETUP begin
      bench.initialize();
    end

    `TEST_CASE("GENip SET F i should OR immediate with flags") begin
      reg [3:0] result;

      bench.rom_data = 12'hF40 | i; // SET F, i

      // p is the initial state of flags
      {bench.cpu_uut.regs.interrupt, bench.cpu_uut.regs.decimal, bench.cpu_uut.regs.zero, bench.cpu_uut.regs.carry} = p;

      result = {bench.cpu_uut.regs.interrupt, bench.cpu_uut.regs.decimal, bench.cpu_uut.regs.zero, bench.cpu_uut.regs.carry} | i;

      bench.run_until_complete();
      #1;

      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);
      bench.assert_cycle_length(7);
  
      bench.assert_carry(result[0]);
      bench.assert_zero(result[1]);
      bench.assert_decimal(result[2]);
      bench.assert_interrupt(result[3]);
    end

    `TEST_CASE("GENip RST F i should AND immediate with flags") begin
      reg [3:0] result;

      bench.rom_data = 12'hF50 | i; // RST F, i

      // p is the initial state of flags
      {bench.cpu_uut.regs.interrupt, bench.cpu_uut.regs.decimal, bench.cpu_uut.regs.zero, bench.cpu_uut.regs.carry} = p;

      result = {bench.cpu_uut.regs.interrupt, bench.cpu_uut.regs.decimal, bench.cpu_uut.regs.zero, bench.cpu_uut.regs.carry} & i;

      bench.run_until_complete();
      #1;

      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);
      bench.assert_cycle_length(7);
  
      bench.assert_carry(result[0]);
      bench.assert_zero(result[1]);
      bench.assert_decimal(result[2]);
      bench.assert_interrupt(result[3]);
    end
  end;

  // The watchdog macro is optional, but recommended. If present, it
  // must not be placed inside any initial or always-block.
  `WATCHDOG(1ns);
endmodule
