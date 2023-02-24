`include "vunit_defines.svh"

module sub_tb;
  core_bench bench();

  parameter r = 0;
  parameter q = 0;
  parameter decimal = 0;

  `TEST_SUITE begin
    `TEST_CASE_SETUP begin
      bench.initialize();
    end

    `TEST_CASE("GENrqd SUB r q should sub and store into r") begin
      reg [3:0] temp_a;
      reg [3:0] temp_b;
      reg [4:0] add_result;
      reg [3:0] result;
      reg carry;

      carry = 0;

      bench.cpu_uut.regs.decimal = decimal;
      bench.cpu_uut.regs.a = 4'h7;
      bench.cpu_uut.regs.b = 4'h9;
      bench.ram[bench.cpu_uut.regs.x] = 4'h4;
      bench.ram[bench.cpu_uut.regs.y] = 4'hB;
      bench.update_prevs();

      bench.rom_data = 12'hAA0 | (r << 2) | q; // SUB r, q

      temp_a = bench.get_r_value(r);
      temp_b = bench.get_r_value(q);

      add_result = temp_a - temp_b;

      if (decimal && add_result[4]) begin
        add_result = add_result - 6;
        carry = 1;
        result = add_result[3:0];
      end else begin
        {carry, result} = add_result;
      end

      bench.run_until_complete();
      #1;

      bench.assert_expected(bench.prev_pc + 1, r == 0 ? result : bench.prev_a, r == 1 ? result : bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);
      bench.assert_cycle_length(7);

      bench.assert_ram(bench.cpu_uut.regs.x, r == 2 ? result : 4'h4);
      bench.assert_ram(bench.cpu_uut.regs.y, r == 3 ? result : 4'hB);
  
      bench.assert_carry(carry);
      bench.assert_zero(result == 4'h0);
    end
  end;

  // The watchdog macro is optional, but recommended. If present, it
  // must not be placed inside any initial or always-block.
  `WATCHDOG(1ns);
endmodule
