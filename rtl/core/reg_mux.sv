import types::*;

module reg_mux (
    input reg_type selector,

    input wire [12:0] pc,
    input wire [11:0] pc_inc,

    input wire [3:0] alu,
    input wire [3:0] flags,

    input wire [3:0] a,
    input wire [3:0] b,

    input wire [3:0] temp_a,
    input wire [3:0] temp_b,

    input wire [11:0] x,
    input wire [11:0] y,

    input wire [7:0] sp,

    input wire [7:0] immed,

    input wire [3:0] memory_read_data,
    output reg use_memory,
    output reg [11:0] memory_addr,
    output reg [3:0] out
);

  always_comb begin
    reg_type modified_selector;

    out = 0;
    memory_addr = 0;
    use_memory = 0;

    if (selector == REG_IMM_ADDR_L || selector == REG_IMM_ADDR_H || selector == REG_IMM_ADDR_P) begin
      modified_selector = imm_addressed_reg(selector, immed[5:0]);
    end else begin
      modified_selector = selector;
    end

    case (modified_selector)
      REG_ALU, REG_ALU_WITH_FLAGS: out = alu;
      REG_FLAGS: out = flags;

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
      REG_MSP_INC: begin
        out = memory_read_data;
        memory_addr = sp + 8'h1;
        use_memory = 1;
      end
      REG_Mn: begin
        out = memory_read_data;
        memory_addr = immed[3:0];
        use_memory = 1;
      end

      REG_IMML: out = immed[3:0];
      REG_IMMH: out = immed[7:4];
      REG_HARDCODED_1: out = 4'h1;

      REG_PCP:  out = pc[11:8];
      REG_PCSH: out = pc[7:4];
      REG_PCSL: out = pc[3:0];

      REG_PCP_INC:  out = pc_inc[11:8];
      REG_PCSH_INC: out = pc_inc[7:4];
      default: begin
        // Do nothing
      end
    endcase
  end

endmodule
