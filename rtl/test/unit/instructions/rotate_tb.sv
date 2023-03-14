`include "vunit_defines.svh"

module rotate_tb;
  core_bench bench();

  parameter r = 0;

  task test_rlc(reg carry);
    reg [3:0] temp_a;
    reg [3:0] result;
    reg output_carry;

    bench.initialize(12'hAF0 | (r << 2) | r); // RLC r

    bench.cpu_uut.regs.carry = carry;
    bench.cpu_uut.regs.a = 4'h1;
    bench.cpu_uut.regs.b = 4'h8;
    bench.ram[bench.cpu_uut.regs.x] = 4'h7;
    bench.ram[bench.cpu_uut.regs.y] = 4'h4;
    bench.update_prevs();

    temp_a = bench.get_r_value(r);

    {output_carry, result} = {temp_a, carry};

    bench.run_until_complete();
    #1;

    bench.assert_expected(bench.prev_pc + 1, r == 0 ? result : bench.prev_a, r == 1 ? result : bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);
    bench.assert_cycle_length(7);

    bench.assert_ram(bench.cpu_uut.regs.x, r == 2 ? result : 4'h7);
    bench.assert_ram(bench.cpu_uut.regs.y, r == 3 ? result : 4'h4);

    bench.assert_carry(output_carry);
    bench.assert_zero(result == 4'h0);
  endtask

  task test_rrc(reg carry);
    reg [3:0] temp_a;
    reg [3:0] result;
    reg output_carry;

    bench.initialize(12'hE8C | r); // RRC r

    bench.cpu_uut.regs.carry = carry;
    bench.cpu_uut.regs.a = 4'h1;
    bench.cpu_uut.regs.b = 4'h8;
    bench.ram[bench.cpu_uut.regs.x] = 4'h7;
    bench.ram[bench.cpu_uut.regs.y] = 4'h4;
    bench.update_prevs();

    temp_a = bench.get_r_value(r);

    {result, output_carry} = {carry, temp_a};

    bench.run_until_complete();
    #1;

    bench.assert_expected(bench.prev_pc + 1, r == 0 ? result : bench.prev_a, r == 1 ? result : bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);
    bench.assert_cycle_length(5);

    bench.assert_ram(bench.cpu_uut.regs.x, r == 2 ? result : 4'h7);
    bench.assert_ram(bench.cpu_uut.regs.y, r == 3 ? result : 4'h4);

    bench.assert_carry(output_carry);
    bench.assert_zero(result == 4'h0);
  endtask

  `TEST_SUITE begin
    `TEST_CASE("GENr RLC should rotate left without carry") begin
      test_rlc(0);
    end

    `TEST_CASE("GENr RLC should rotate left with carry") begin
      test_rlc(1);
    end

    `TEST_CASE("GENr RRC should rotate right without carry") begin
      test_rrc(0);
    end

    `TEST_CASE("GENr RRC should rotate right with carry") begin
      test_rrc(1);
    end
  end;

  // The watchdog macro is optional, but recommended. If present, it
  // must not be placed inside any initial or always-block.
  `WATCHDOG(1ns);
endmodule
