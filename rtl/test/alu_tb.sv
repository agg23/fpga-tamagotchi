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
    else $error("Did not add to: %d. Actual: %d", expected, out);

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

  initial begin
    // Test add
    // --------
    // 0 + 0 = 0
    assert_add(0, 0, 0, 0, 0);

    // 0 + 0 + 0 = 0
    op_use_carry = 1;
    assert_add(0, 0, 0, 0, 0);

    // 0 + 0 + 1 = 1
    assert_add(0, 0, 1, 1, 0);

    // 1 + 0 + 1 = 2
    assert_add(1, 0, 1, 2, 0);

    // 1 + 1 + 1 = 3
    assert_add(1, 1, 1, 3, 0);

    // 1 + 1 + 0 = 2
    assert_add(1, 1, 0, 2, 0);

    // 7 + 8 + 0 = 15
    assert_add(7, 8, 0, 15, 0);

    // 7 + 8 + 1 = 0 + 0x10
    assert_add(7, 8, 1, 0, 1);

    // 10 + 10 + 1 = 5 + 0x10
    assert_add(10, 10, 1, 5, 1);

    // Carry should be ignored if `op_use_carry` is false
    op_use_carry = 0;
    // 10 + 10 + 1 (ignored) = 4 + 0x10
    assert_add(10, 10, 1, 4, 1);

    // Test decimal mode
    decimal_in = 1;
    // 1 + 1 + 0 = 2
    assert_add(1, 1, 0, 2, 0);

    // 9 + 0 + 1 (ignored) = 9
    assert_add(9, 0, 1, 9, 0);

    // 9 + 0 + 1 = 0 + 10
    op_use_carry = 1;
    assert_add(9, 0, 1, 0, 1);

    // 0 + 15 + 0 = 5 + 10
    assert_add(0, 15, 0, 5, 1);

    // 10 + 15 + 0 = 15 + 10
    assert_add(10, 15, 0, 15, 1);

    // 15 + 15 + 1 = 5 + 10 + 16
    assert_add(15, 15, 1, 5, 1);
  end

endmodule
