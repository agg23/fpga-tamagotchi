`include "vunit_defines.svh"

module pop_tb;
  parameter r = 0;

  core_bench bench();

  `TEST_SUITE begin
    `TEST_CASE_SETUP begin
      bench.initialize();
    end

    `TEST_CASE("GENr POP r should pop value from stack and store into r") begin
      reg [11:0] opcode;

      bench.rom_data = 12'hFD0 | r; // POP r
      bench.ram[bench.prev_sp] = 4'hA;

      bench.run_until_complete();
      #1;
      bench.assert_expected(bench.prev_pc + 1, r == 0 ? 4'hA : bench.prev_a, r == 1 ? 4'hA : bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp + 1);
      bench.assert_cycle_length(5);

      bench.assert_ram(bench.prev_x, r == 2 ? 4'hA : 4'h0);
      bench.assert_ram(bench.prev_y, r == 3 ? 4'hA : 4'h0);
    end

    `TEST_CASE("POP XP should pop value from stack and store into XP") begin
      bench.rom_data = 12'hFD4; // POP XP
      bench.ram[bench.prev_sp] = 4'hA;

      bench.run_until_complete();
      #1;
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, (bench.prev_x & 12'h0FF) | (4'hA << 8), bench.prev_y, bench.prev_sp + 1);
      bench.assert_cycle_length(5);
    end

    `TEST_CASE("POP XH should pop value from stack and store into XH") begin
      bench.rom_data = 12'hFD5; // POP XH
      bench.ram[bench.prev_sp] = 4'hA;

      bench.run_until_complete();
      #1;
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, (bench.prev_x & 12'hF0F) | (4'hA << 4), bench.prev_y, bench.prev_sp + 1);
      bench.assert_cycle_length(5);
    end

    `TEST_CASE("POP XL should pop value from stack and store into XL") begin
      bench.rom_data = 12'hFD6; // POP XL
      bench.ram[bench.prev_sp] = 4'hA;

      bench.run_until_complete();
      #1;
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, (bench.prev_x & 12'hFF0) | (4'hA), bench.prev_y, bench.prev_sp + 1);
      bench.assert_cycle_length(5);
    end

    `TEST_CASE("POP YP should pop value from stack and store into YP") begin
      bench.rom_data = 12'hFD7; // POP YP
      bench.ram[bench.prev_sp] = 4'hA;

      bench.run_until_complete();
      #1;
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, (bench.prev_y & 12'h0FF) | (4'hA << 8), bench.prev_sp + 1);
      bench.assert_cycle_length(5);
    end

    `TEST_CASE("POP YH should pop value from stack and store into YH") begin
      bench.rom_data = 12'hFD8; // POP YH
      bench.ram[bench.prev_sp] = 4'hA;

      bench.run_until_complete();
      #1;
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, (bench.prev_y & 12'hF0F) | (4'hA << 4), bench.prev_sp + 1);
      bench.assert_cycle_length(5);
    end

    `TEST_CASE("POP YL should pop value from stack and store into YL") begin
      bench.rom_data = 12'hFD9; // POP YL
      bench.ram[bench.prev_sp] = 4'hA;

      bench.run_until_complete();
      #1;
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, (bench.prev_y & 12'hFF0) | (4'hA), bench.prev_sp + 1);
      bench.assert_cycle_length(5);
    end

    `TEST_CASE("POP F should pop value from stack and store into flags") begin
      bench.rom_data = 12'hFDA; // POP F
      bench.ram[bench.prev_sp] = 4'hA;

      bench.run_until_complete();
      #1;
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp + 1);
      bench.assert_cycle_length(5);

      bench.assert_carry(0);
      bench.assert_zero(1);
      bench.assert_decimal(0);
      bench.assert_interrupt(1);
    end
  end;

  // The watchdog macro is optional, but recommended. If present, it
  // must not be placed inside any initial or always-block.
  `WATCHDOG(1ns);
endmodule
