`include "vunit_defines.svh"

module inc_tb;
  core_bench bench();

  parameter i = 0;

  `TEST_SUITE begin
    `TEST_CASE_SETUP begin
      bench.initialize();
    end

    `TEST_CASE("GENi INC Mn should increment Mn and update flags") begin
      reg [3:0] result;
      reg carry;
      int j;

      bench.rom_data = 12'hF60 | i; // INC Mn
      for (j = 0; j < 16; j = j + 1) begin
        // Offset from immediate to prevent logic depending on it
        bench.ram[j] = j + 2;
      end

      {carry, result} = bench.ram[i] + 1;

      bench.run_until_complete();
      #1;

      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);
      bench.assert_cycle_length(7);

      bench.assert_ram(i, result);
  
      bench.assert_carry(carry);
      bench.assert_zero(result == 4'h0);
    end

    `TEST_CASE("GENi DEC Mn should decrement Mn and update flags") begin
      reg [3:0] result;
      reg carry;
      int j;

      bench.rom_data = 12'hF70 | i; // DEC Mn
      for (j = 0; j < 16; j = j + 1) begin
        // Offset from immediate to prevent logic depending on it
        bench.ram[j] = j + 2;
      end

      {carry, result} = bench.ram[i] - 1;

      bench.run_until_complete();
      #1;

      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);
      bench.assert_cycle_length(7);

      bench.assert_ram(i, result);
  
      bench.assert_carry(carry);
      bench.assert_zero(result == 4'h0);
    end

    `TEST_CASE("DEC SP should decrement SP") begin
      bench.rom_data = 12'hFCB; // DEC SP

      bench.run_until_complete();
      #1;

      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp - 1);
      bench.assert_cycle_length(5);
    end

    `TEST_CASE("INC SP should increment SP") begin
      bench.rom_data = 12'hFDB; // INC SP

      bench.run_until_complete();
      #1;

      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp + 1);
      bench.assert_cycle_length(5);
    end
  end;

  // The watchdog macro is optional, but recommended. If present, it
  // must not be placed inside any initial or always-block.
  `WATCHDOG(1ns);
endmodule
