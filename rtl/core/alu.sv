import types::*;

module alu (
    input alu_op op,

    input wire [3:0] temp_a,
    input wire [3:0] temp_b,

    input wire flag_carry_in,
    input wire flag_decimal_in,

    output reg [3:0] out,
    output reg flag_carry_out,
    output reg flag_zero_out
);

  always_comb begin
    out = 0;
    flag_carry_out = flag_carry_in;

    case (op)
      ALU_ADD, ALU_ADD_NO_DEC, ALU_ADC, ALU_ADC_NO_DEC: begin
        reg [4:0] add_result;
        reg op_use_carry;

        op_use_carry = op == ALU_ADC || op == ALU_ADC_NO_DEC;
        // Highest bit is the carry
        add_result   = temp_a + temp_b + {4'b0, op_use_carry && flag_carry_in};

        if (op != ALU_ADD_NO_DEC && op != ALU_ADC_NO_DEC && flag_decimal_in && add_result >= 10) begin
          add_result = (add_result - 10);
          out = add_result[3:0];
          flag_carry_out = 1;
        end else begin
          {flag_carry_out, out} = add_result;
        end
      end
      ALU_SUB, ALU_SUB_NO_DEC, ALU_SBC, ALU_CP: begin
        reg [4:0] sub_result;

        // Only include carry if ALU_SBC
        sub_result = temp_a - temp_b - {4'b0, op == ALU_SBC && flag_carry_in};

        // Decimal mode isn't used for CP
        if (op != ALU_CP && op != ALU_SUB_NO_DEC && flag_decimal_in && sub_result[4]) begin
          // Carry is set
          sub_result = (sub_result - 6);
          out = sub_result[3:0];
          flag_carry_out = 1;
        end else begin
          {flag_carry_out, out} = sub_result;
        end
      end
      ALU_AND: begin
        out = temp_a & temp_b;
      end
      ALU_OR: begin
        out = temp_a | temp_b;
      end
      ALU_XOR: begin
        out = temp_a ^ temp_b;
      end
      ALU_RRC: begin
        // Carry becomes highest bit, lowest bit becomes carry
        // TODO: Documentation conflicts on whether or not zero is set. I think it makes more sense that it is
        {out, flag_carry_out} = {flag_carry_in, temp_a};
      end
      ALU_RLC: begin
        // Carry becomes lowest bit, highest bit becomes carry
        // TODO: Documentation conflicts on whether or not zero is set. I think it makes more sense that it is
        {flag_carry_out, out} = {temp_a, flag_carry_in};
      end
      // ALU_NOT: begin
      //   out = ~temp_a;
      // end
    endcase

    flag_zero_out = out == 0;
  end

endmodule
