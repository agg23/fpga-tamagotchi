import types::*;

module alu_tb;
  alu_op op;
  reg op_use_carry = 0;

  reg [3:0] temp_a = 0;
  reg [3:0] temp_b = 0;

  reg carry_in = 0;
  reg decimal_in = 0;

  wire [3:0] out;
  wire carry_out;
  wire zero_out;

  alu alu_uut (
      .op(op),
      .op_use_carry(op_use_carry),

      .temp_a(temp_a),
      .temp_b(temp_b),

      .flag_carry_in  (carry_in),
      .flag_decimal_in(decimal_in),

      .out(out),
      .flag_carry_out(carry_out),
      .flag_zero_out(zero_out)
  );

  task assert_output(reg [3:0] expected);
    assert (out == expected)
    else $error("Did not output expected: %d. Actual: %d", expected, out);

    assert (zero_out == (expected == 0))
    else $error("Zero flag was not correct");
  endtask

  task assert_carry(reg set);
    assert (carry_out == set)
    else $error("Carry was not %b", set);
  endtask

  task assert_alu(alu_op current_op, reg [3:0] a, reg [3:0] b, reg carry, reg [3:0] expected,
                  reg expected_carry);
    op = current_op;
    temp_a = a;
    temp_b = b;
    carry_in = carry;

    #1;

    assert_output(expected);
    assert_carry(expected_carry);
  endtask

  task assert_add(reg [3:0] a, reg [3:0] b, reg carry, reg [3:0] expected, reg expected_carry);
    assert_alu(ALU_ADD, a, b, carry, expected, expected_carry);
  endtask

  task assert_sub(reg [3:0] a, reg [3:0] b, reg carry, reg [3:0] expected, reg expected_carry);
    assert_alu(ALU_SUB, a, b, carry, expected, expected_carry);
  endtask

  task assert_and(reg [3:0] a, reg [3:0] b, reg carry, reg [3:0] expected, reg expected_carry);
    assert_alu(ALU_AND, a, b, carry, expected, expected_carry);
  endtask

  task assert_or(reg [3:0] a, reg [3:0] b, reg carry, reg [3:0] expected, reg expected_carry);
    assert_alu(ALU_OR, a, b, carry, expected, expected_carry);
  endtask

  task assert_xor(reg [3:0] a, reg [3:0] b, reg carry, reg [3:0] expected, reg expected_carry);
    assert_alu(ALU_XOR, a, b, carry, expected, expected_carry);
  endtask

  task assert_rrc(reg [3:0] a, reg [3:0] b, reg carry, reg [3:0] expected, reg expected_carry);
    assert_alu(ALU_RRC, a, b, carry, expected, expected_carry);
  endtask

  task assert_rlc(reg [3:0] a, reg [3:0] b, reg carry, reg [3:0] expected, reg expected_carry);
    assert_alu(ALU_RLC, a, b, carry, expected, expected_carry);
  endtask

  task assert_not(reg [3:0] a, reg [3:0] b, reg carry, reg [3:0] expected, reg expected_carry);
    assert_alu(ALU_NOT, a, b, carry, expected, expected_carry);
  endtask

  initial begin
    // Test ADD
    // --------
    // 1: 0 + 0 = 0
    assert_add(0, 0, 0, 0, 0);

    // 2: 0 + 0 + 0 = 0
    op_use_carry = 1;
    assert_add(0, 0, 0, 0, 0);

    // 3: 0 + 0 + 1 = 1
    assert_add(0, 0, 1, 1, 0);

    // 4: 1 + 0 + 1 = 2
    assert_add(1, 0, 1, 2, 0);

    // 5: 1 + 1 + 1 = 3
    assert_add(1, 1, 1, 3, 0);

    // 6: 1 + 1 + 0 = 2
    assert_add(1, 1, 0, 2, 0);

    // 7: 7 + 8 + 0 = 15
    assert_add(7, 8, 0, 15, 0);

    // 8: 7 + 8 + 1 = 0 + 0x10
    assert_add(7, 8, 1, 0, 1);

    // 9: 10 + 10 + 1 = 5 + 0x10
    assert_add(10, 10, 1, 5, 1);

    // Carry should be ignored if `op_use_carry` is false
    op_use_carry = 0;
    // 10: 10 + 10 + 1 (ignored) = 4 + 0x10
    assert_add(10, 10, 1, 4, 1);

    // Test decimal mode
    decimal_in = 1;
    // 11: 1 + 1 + 0 = 2
    assert_add(1, 1, 0, 2, 0);

    // 12: 9 + 0 + 1 (ignored) = 9
    assert_add(9, 0, 1, 9, 0);

    // 13: 9 + 0 + 1 = 0 + 10
    op_use_carry = 1;
    assert_add(9, 0, 1, 0, 1);

    // 14: 0 + 15 + 0 = 5 + 10
    assert_add(0, 15, 0, 5, 1);

    // 15: 10 + 15 + 0 = 15 + 10
    assert_add(10, 15, 0, 15, 1);

    // 16: 15 + 15 + 1 = 5 + 10 + 16
    assert_add(15, 15, 1, 5, 1);


    // Test SUB
    // --------
    op_use_carry = 0;
    decimal_in   = 0;

    // 17: 0 - 0 = 0
    assert_sub(0, 0, 0, 0, 0);

    // 18: 0 - 0 - 0 = 0
    op_use_carry = 1;
    assert_sub(0, 0, 0, 0, 0);

    // 19: 0 - 0 - 1 = -1
    assert_sub(0, 0, 1, 4'hF, 1);

    // 20: 1 - 0 - 1 = 0
    assert_sub(1, 0, 1, 0, 0);

    // 21: 1 - 1 - 1 = -1
    assert_sub(1, 1, 1, 4'hF, 1);

    // 22: 2 - 1 - 0 = 1
    assert_sub(2, 1, 0, 1, 0);

    // 23: 7 - 8 + 0 = -1
    assert_sub(7, 8, 0, 4'hF, 1);

    // 24: 7 - 8 - 1 = -2
    assert_sub(7, 8, 1, 4'hE, 1);

    // 25: 0 - 15 - 0 = -15
    assert_sub(0, 15, 0, 1, 1);

    // 26: 15 - 15 - 0 = 0
    assert_sub(15, 15, 0, 0, 0);

    // 27: 10 - 15 - 1 = -6
    assert_sub(10, 15, 1, 4'hA, 1);

    // Carry should be ignored if `op_use_carry` is false
    op_use_carry = 0;
    // 28: 15 - 10 - 1 (ignored) = 5
    assert_sub(15, 10, 1, 5, 0);

    // 29: 5 - 10 - 1 (ignored) = -5
    assert_sub(5, 10, 1, 4'hB, 1);

    // Test decimal mode
    decimal_in = 1;
    // 30: 4 - 15 - 0 = -1 - 10
    assert_sub(4, 15, 0, 4'hF, 1);

    // 31: 0 - 1 - 1 (ignored) = 9 - 10
    assert_sub(0, 1, 1, 9, 1);

    // 32: 0 - 1 - 1 = 8 - 10
    op_use_carry = 1;
    assert_sub(0, 1, 1, 8, 1);

    // 33: 0 - 9 - 1 = 0 - 10
    assert_sub(0, 9, 1, 0, 1);

    // 34: 0 - 10 - 1 = -1 - 10
    assert_sub(0, 10, 1, 4'hF, 1);

    // 35: 15 - 1 - 1 = 13
    assert_sub(15, 1, 1, 13, 0);


    // Test AND
    // --------
    // 36: F & 0 = 0
    assert_and(4'hF, 0, 0, 0, 0);

    // 37: F & F = F
    assert_and(4'hF, 4'hF, 0, 4'hF, 0);

    // 38: 9 & 1 = 1
    assert_and(4'h9, 4'h1, 0, 4'h1, 0);

    // 39: A & 8 = 8
    assert_and(4'hA, 4'h8, 0, 4'h8, 0);


    // Test OR
    // --------
    // 40: A | 5 = F
    assert_or(4'hA, 4'h5, 0, 4'hF, 0);

    // 41: F | 0 = F
    assert_or(4'hF, 4'h0, 0, 4'hF, 0);

    // 42: 1 | 2 = 3
    assert_or(4'h1, 4'h2, 0, 4'h3, 0);

    // 43: A | C = E
    assert_or(4'hA, 4'hC, 0, 4'hE, 0);


    // Test XOR
    // --------
    // 44: A ^ 5 = F
    assert_xor(4'hA, 4'h5, 0, 4'hF, 0);

    // 45: A ^ 7 = D
    assert_xor(4'hA, 4'h7, 0, 4'hD, 0);

    // 46: F ^ 3 = C
    assert_xor(4'hF, 4'h3, 0, 4'hC, 0);

    // 47: 1 ^ 3 = 2
    assert_xor(4'h1, 4'h3, 0, 4'h2, 0);


    // Test RRC
    // --------
    // 48: F + 1 => F + 1
    assert_rrc(4'hF, 0, 1, 4'hF, 1);

    // 49: F + 0 => 7 + 1
    assert_rrc(4'hF, 1, 0, 4'h7, 1);

    // 50: 1 + 1 => 8 + 1
    // Should ignore op_use_carry
    op_use_carry = 0;
    assert_rrc(4'h1, 1, 1, 4'h8, 1);

    // 51: 1 + 0 => 8 + 1
    assert_rrc(4'h1, 1, 0, 0, 1);


    // Test RLC
    // --------
    // 52: F + 1 => F + 1
    assert_rlc(4'hF, 0, 1, 4'hF, 1);

    // 53: F + 0 => E + 1
    assert_rlc(4'hF, 0, 0, 4'hE, 1);

    // 54: 1 + 1 => 3 + 0
    // Should ignore op_use_carry
    op_use_carry = 1;
    assert_rlc(4'h1, 0, 1, 4'h3, 0);

    // 55: 1 + 0 => 2 + 0
    assert_rlc(4'h1, 1, 0, 2, 0);


    // Test NOT
    // --------
    // 56: ~F = 0
    assert_not(4'hF, 0, 0, 4'h0, 0);

    // 57: ~0 = F
    assert_not(4'h0, 3, 1, 4'hF, 1);

    // 58: ~3 = C
    assert_not(4'h3, 3, 1, 4'hC, 1);

    // 59: ~E = 1
    assert_not(4'hE, 0, 0, 4'h1, 0);
  end

endmodule
