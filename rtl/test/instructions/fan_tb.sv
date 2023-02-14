`include "vunit_defines.svh"

module fan_tb;
  bench bench();

  parameter r = 0;

  `TEST_SUITE begin
    `TEST_CASE_SETUP begin
      bench.initialize();
    end

    `TEST_CASE("GENr FAN r i should AND immediate with r and set zero flag") begin
      reg [3:0] temp_a;
      reg [3:0] result;

      bench.cpu_uut.regs.a = 4'h1;
      bench.cpu_uut.regs.b = 4'h8;
      bench.ram[bench.cpu_uut.regs.x] = 4'h5;
      bench.ram[bench.cpu_uut.regs.y] = 4'hE;
      bench.update_prevs();

      bench.rom_data = 12'hD84 | (r << 4); // FAN r, i

      temp_a = bench.get_r_value(r);

      result = temp_a & 4'h4;

      bench.run_until_complete();
      #1;

      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);
      bench.assert_cycle_length(7);

      bench.assert_ram(bench.cpu_uut.regs.x, 4'h5);
      bench.assert_ram(bench.cpu_uut.regs.y, 4'hE);
  
      bench.assert_carry(bench.prev_carry);
      bench.assert_zero(result == 4'h0);
    end
  end;

  // The watchdog macro is optional, but recommended. If present, it
  // must not be placed inside any initial or always-block.
  `WATCHDOG(1ns);
endmodule
