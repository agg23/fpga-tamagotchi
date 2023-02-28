package types;
  typedef enum {
    ALU_ADD,
    ALU_ADD_NO_DEC,
    ALU_ADC,
    ALU_ADC_NO_DEC,
    ALU_SUB,
    ALU_SUB_NO_DEC,
    ALU_SBC,
    ALU_AND,
    ALU_OR,
    ALU_XOR,
    ALU_CP,
    // ALU_FAN
    ALU_RRC,
    ALU_RLC
    // ALU_NOT
  } alu_op;

  typedef enum {
    REG_FLAGS,
    REG_A,
    REG_B,
    REG_TEMPA,
    REG_TEMPB,
    REG_XL,
    REG_XH,
    REG_XP,
    REG_YL,
    REG_YH,
    REG_YP,
    REG_SPL,
    REG_SPH,
    REG_MX,
    REG_MY,
    REG_MSP,
    REG_MSP_INC,  // M(SP + 1)
    REG_MSP_DEC,  // M(SP - 1)
    REG_Mn,
    REG_PCSL,
    REG_PCSH,
    REG_PCP,
    REG_PCP_EARLY,
    REG_NBP,
    REG_NPP,
    REG_IMML,
    REG_IMMH,
    REG_HARDCODED_1,
    REG_IMM_ADDR_L,  // r or q used in position 1:0
    REG_IMM_ADDR_H,  // r or q used in position 3:2
    REG_IMM_ADDR_P,  // r or q used in position 5:4

    // Custom "registers" that represent hardcoded multiple registers to be set simultaneously
    REG_SETPC,  // Copy 8 bit immediate to PCS, NBP to PCB, and NPP to PCP. Set in fetch
    REG_CALLEND_ZERO_PCP,  // Transfer PCLS+1 to M(SP), and copy 8 bit immediate to PC (set in fetch). Set PCP to 0
    REG_CALLEND_SET_PCP,  // Transfer PCLS+1 to M(SP), and copy 8 bit immediate to PC (set in fetch). Set PCP to NPP
    REG_JPBAEND,  // Transfer A to PCSL, NBP to PCB, and NPP to PCP
    REG_STARTINTERRUPT,  // Transfer PCP to M(SP - 1) and decrement SP. Disable interrupt flag
    REG_PCP_INC,
    REG_PCSH_INC,

    REG_ALU,
    REG_ALU_WITH_FLAGS
  } reg_type;

  typedef enum {
    REG_NONE,
    REG_XHL,
    REG_YHL,
    REG_SP_INC,
    REG_SP_DEC,
    REG_PC  // Special case used only for halt
  } reg_inc_type;

  typedef enum {
    CYCLE_NONE,
    CYCLE_REG_FETCH,
    CYCLE_REG_WRITE
  } microcode_cycle;

  typedef enum {
    CYCLE5,
    CYCLE7,
    CYCLE12
  } instr_length;

  function [3:0] cycle_count_int(instr_length length);
    case (length)
      CYCLE5:  cycle_count_int = 5;
      CYCLE7:  cycle_count_int = 7;
      CYCLE12: cycle_count_int = 12;
    endcase
  endfunction

  function reg_type imm_addressed_reg(reg_type input_reg, reg [5:0] immed);
    reg [1:0] selected_imm;

    selected_imm = 0;

    case (input_reg)
      REG_IMM_ADDR_L: selected_imm = immed[1:0];
      REG_IMM_ADDR_H: selected_imm = immed[3:2];
      REG_IMM_ADDR_P: selected_imm = immed[5:4];
      default: begin
        // Do nothing
      end
    endcase

    case (selected_imm)
      2'b00: imm_addressed_reg = REG_A;
      2'b01: imm_addressed_reg = REG_B;
      2'b10: imm_addressed_reg = REG_MX;
      2'b11: imm_addressed_reg = REG_MY;
    endcase
  endfunction
endpackage
