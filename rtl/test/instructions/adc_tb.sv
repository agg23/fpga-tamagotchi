`include "vunit_defines.svh"

module adc_tb;
  parameter r = 0;
  parameter q = 0;
  parameter decimal = 0;

  bench bench();

  task test_adc_rq(reg [11:0] opcode, reg carry, reg use_immediate, reg [3:0] value);
    reg [3:0] temp_a;
    reg [3:0] temp_b;
    reg [4:0] add_result;
    reg [3:0] result;
    reg output_carry;

    output_carry = 0;

    bench.cpu_uut.regs.carry = carry;
    bench.cpu_uut.regs.decimal = decimal;
    bench.cpu_uut.regs.a = 4'h7;
    bench.cpu_uut.regs.b = 4'h9;
    bench.ram[bench.cpu_uut.regs.x] = 4'h4;
    bench.ram[bench.cpu_uut.regs.y] = 4'hB;
    bench.update_prevs();

    bench.rom_data = opcode;

    temp_a = bench.get_r_value(r);
    if (use_immediate) begin
      temp_b = value;
    end else begin
      temp_b = bench.get_r_value(q);
    end

    add_result = temp_a + temp_b + carry;

    if (decimal && add_result >= 10) begin
      add_result = add_result - 10;
      output_carry = 1;
      result = add_result[3:0];
    end else begin
      {output_carry, result} = add_result;
    end

    bench.run_until_complete();
    #1;

    bench.assert_expected(bench.prev_pc + 1, r == 0 ? result : bench.prev_a, r == 1 ? result : bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);
    bench.assert_cycle_length(7);

    bench.assert_ram(bench.cpu_uut.regs.x, r == 2 ? result : 4'h4);
    bench.assert_ram(bench.cpu_uut.regs.y, r == 3 ? result : 4'hB);

    bench.assert_carry(output_carry);
    bench.assert_zero(result == 4'h0);
  endtask

  `TEST_SUITE begin
    `TEST_CASE_SETUP begin
      bench.initialize();
    end

    `TEST_CASE("ADC XH i should load with 4 bit immediate") begin
      bench.rom_data = 12'hA0F; // ADC XH, i

      bench.run_until_complete();
      #1;

      // 2 + F = 1 + c
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, 12'h212, bench.prev_y, bench.prev_sp);
      bench.assert_cycle_length(7);
      bench.assert_carry(1);
      bench.assert_zero(0);
    end

    `TEST_CASE("ADC XL i should load with 4 bit immediate") begin
      bench.rom_data = 12'hA1E; // ADC XL, i

      bench.run_until_complete();
      #1;

      // 2 + E = 0 + c
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, 12'h220, bench.prev_y, bench.prev_sp);
      bench.assert_cycle_length(7);
      bench.assert_carry(1);
      bench.assert_zero(1);
    end

    `TEST_CASE("ADC YH i should load with 4 bit immediate") begin
      bench.rom_data = 12'hA27; // ADC YH, i

      bench.run_until_complete();
      #1;

      // 3 + 7 = A
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, 12'h3A3, bench.prev_sp);
      bench.assert_cycle_length(7);
      bench.assert_carry(0);
      bench.assert_zero(0);
    end

    `TEST_CASE("ADC YL i should load with 4 bit immediate") begin
      bench.rom_data = 12'hA3D; // ADC YL, i

      bench.run_until_complete();
      #1;

      // 3 + D = 0 + c
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, 12'h330, bench.prev_sp);
      bench.assert_cycle_length(7);
      bench.assert_carry(1);
      bench.assert_zero(1);
    end

    `TEST_CASE("GENrqd ADC r q should add and store into r without carry") begin
      reg [11:0] opcode;
      opcode = 12'hA90 | (r << 2) | q; // ADC r, q

      test_adc_rq(opcode, 0, 0, 0);
    end

    `TEST_CASE("GENrqd ADC r q should add and store into r with carry") begin
      reg [11:0] opcode;
      opcode = 12'hA90 | (r << 2) | q; // ADC r, q

      test_adc_rq(opcode, 1, 0, 0);
    end

    `TEST_CASE("GENrd ADC r i should add with immediate and store into r without carry") begin
      reg [11:0] opcode;
      opcode = 12'hC47 | (r << 4); // ADC r, i

      test_adc_rq(opcode, 0, 1, 4'h7);
    end

    `TEST_CASE("GENrd ADC r i should add with immediate and store into r with carry") begin
      reg [11:0] opcode;
      opcode = 12'hC47 | (r << 4); // ADC r, i

      test_adc_rq(opcode, 1, 1, 4'h7);
    end
  end;

  // The watchdog macro is optional, but recommended. If present, it
  // must not be placed inside any initial or always-block.
  `WATCHDOG(1ns);
endmodule
