import types::*;

module reg_mux (
    input reg_type selector,

    input wire [3:0] alu,

    input wire [3:0] a,
    input wire [3:0] b,

    input wire [3:0] temp_a,
    input wire [3:0] temp_b,

    input wire [11:0] x,
    input wire [11:0] y,

    input wire [7:0] sp,

    input wire [3:0] immed,

    input wire [3:0] memory_read_data,
    output reg use_memory,
    output reg [11:0] memory_addr,
    output reg [3:0] out
);

  always_comb begin
    out = 0;
    memory_addr = 0;
    use_memory = 0;

    case (selector)
      REG_ALU: out = alu;

      REG_A: out = a;
      REG_B: out = b;

      REG_TEMPA: out = temp_a;
      REG_TEMPB: out = temp_b;

      REG_XL: out = x[3:0];
      REG_XH: out = x[7:4];
      REG_XP: out = x[11:8];

      REG_YL: out = y[3:0];
      REG_YH: out = y[7:4];
      REG_YP: out = y[11:8];

      REG_SPL: out = sp[3:0];
      REG_SPH: out = sp[7:4];

      REG_MX: begin
        out = memory_read_data;
        memory_addr = x;
        use_memory = 1;
      end
      REG_MY: begin
        out = memory_read_data;
        memory_addr = y;
        use_memory = 1;
      end
      REG_MSP: begin
        out = memory_read_data;
        memory_addr = sp;  // TODO: This might not work due to adjustments on SP
        use_memory = 1;
      end
      REG_Mn: begin
        out = memory_read_data;
        memory_addr = immed;
        use_memory = 1;
      end

      REG_IMM: out = immed;
      REG_HARDCODED_1: out = 4'h1;
    endcase
  end

endmodule
