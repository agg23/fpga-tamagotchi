`include "vunit_defines.svh"

module xor_tb;
  bench bench();

  parameter r = 0;
  parameter q = 0;

  `TEST_SUITE begin
    `TEST_CASE_SETUP begin
      bench.initialize();
    end

    `TEST_CASE("GENrq XOR r q should bitwise XOR and store into r") begin
      reg [3:0] temp_a;
      reg [3:0] temp_b;
      reg [3:0] result;

      bench.cpu_uut.regs.a = 4'h1;
      bench.cpu_uut.regs.b = 4'hF;
      bench.ram[bench.cpu_uut.regs.x] = 4'h7;
      bench.ram[bench.cpu_uut.regs.y] = 4'h7;
      bench.update_prevs();

      bench.rom_data = 12'hAE0 | (r << 2) | q; // XOR r, q

      temp_a = bench.get_r_value(r);
      temp_b = bench.get_r_value(q);

      result = temp_a ^ temp_b;

      bench.run_until_complete();
      #1;

      bench.assert_expected(bench.prev_pc + 1, r == 0 ? result : bench.prev_a, r == 1 ? result : bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);
      bench.assert_cycle_length(7);

      bench.assert_ram(bench.cpu_uut.regs.x, r == 2 ? result : 4'h7);
      bench.assert_ram(bench.cpu_uut.regs.y, r == 3 ? result : 4'h7);
  
      bench.assert_carry(bench.prev_carry);
      bench.assert_zero(result == 4'h0);
    end

    `TEST_CASE("GENr XOR r i should bitwise XOR with immediate and store into r") begin
      reg [3:0] temp_a;
      reg [3:0] result;

      bench.cpu_uut.regs.a = 4'h1;
      bench.cpu_uut.regs.b = 4'hF;
      bench.ram[bench.cpu_uut.regs.x] = 4'h7;
      bench.ram[bench.cpu_uut.regs.y] = 4'h7;
      bench.update_prevs();

      bench.rom_data = 12'hD01 | (r << 4); // XOR r, i

      temp_a = bench.get_r_value(r);

      result = temp_a ^ 4'h1;

      bench.run_until_complete();
      #1;

      bench.assert_expected(bench.prev_pc + 1, r == 0 ? result : bench.prev_a, r == 1 ? result : bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);
      bench.assert_cycle_length(7);

      bench.assert_ram(bench.cpu_uut.regs.x, r == 2 ? result : 4'h7);
      bench.assert_ram(bench.cpu_uut.regs.y, r == 3 ? result : 4'h7);
  
      bench.assert_carry(bench.prev_carry);
      bench.assert_zero(result == 4'h0);
    end
  end;

  // The watchdog macro is optional, but recommended. If present, it
  // must not be placed inside any initial or always-block.
  `WATCHDOG(1ns);
endmodule
