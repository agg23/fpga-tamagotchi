`include "vunit_defines.svh"

module cp_tb;
  parameter r = 0;

  bench bench();

  function [1:0] cp_flags(reg [3:0] a, reg [3:0] b);
    if (a > b) begin
      cp_flags = {1'b0, 1'b0};
    end else if (a < b) begin
      cp_flags = {1'b1, 1'b0};
    end else begin
      cp_flags = {1'b0, 1'b1};
    end
  endfunction

  `TEST_SUITE begin
    `TEST_CASE_SETUP begin
      bench.initialize();
    end

    `TEST_CASE("CP XH i should set flags") begin
      bench.rom_data = 12'hA4F; // CP XH, i

      bench.run_until_complete();
      #1;

      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);
      bench.assert_cycle_length(7);

      // F > 2
      bench.assert_carry(1);
      bench.assert_zero(0);
    end

    `TEST_CASE("CP XL i should set flags") begin
      bench.rom_data = 12'hA52; // CP XL, i

      bench.run_until_complete();
      #1;

      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);
      bench.assert_cycle_length(7);

      // 2 == 2
      bench.assert_carry(0);
      bench.assert_zero(1);
    end

    `TEST_CASE("CP YH i should set flags") begin
      bench.rom_data = 12'hA62; // CP YH, i

      bench.run_until_complete();
      #1;

      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);
      bench.assert_cycle_length(7);

      // 2 < 3
      bench.assert_carry(0);
      bench.assert_zero(0);
    end

    `TEST_CASE("CP YL i should set flags") begin
      bench.rom_data = 12'hA74; // CP YH, i

      bench.run_until_complete();
      #1;

      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);
      bench.assert_cycle_length(7);

      // 4 > 3
      bench.assert_carry(1);
      bench.assert_zero(0);
    end

    `TEST_CASE("GENr CP r i should set flags") begin
      reg [3:0] temp_a;
      reg carry;
      reg zero;

      bench.cpu_uut.regs.a = 4'h1;
      bench.cpu_uut.regs.b = 4'h8;
      bench.ram[bench.cpu_uut.regs.x] = 4'h5;
      bench.ram[bench.cpu_uut.regs.y] = 4'hE;
      bench.update_prevs();

      bench.rom_data = 12'hDC4 | (r << 4); // CP r, i

      temp_a = bench.get_r_value(r);

      {carry, zero} = cp_flags(temp_a, 4'h4);

      bench.run_until_complete();
      #1;

      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);
      bench.assert_cycle_length(7);

      bench.assert_ram(bench.cpu_uut.regs.x, 4'h5);
      bench.assert_ram(bench.cpu_uut.regs.y, 4'hE);
  
      bench.assert_carry(carry);
      bench.assert_zero(zero);
    end

  end;

  // The watchdog macro is optional, but recommended. If present, it
  // must not be placed inside any initial or always-block.
  `WATCHDOG(1ns);
endmodule
