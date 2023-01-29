package types;
  typedef enum {
    ALU_ADD,
    ALU_SUB,
    ALU_AND,
    ALU_OR,
    ALU_XOR,
    ALU_CP,
    // ALU_FAN
    ALU_RRC,
    ALU_RLC,
    ALU_NOT
  } alu_op;

  typedef enum {
    REG_ALU,
    REG_ALU_WITH_FLAGS,
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
    REG_Mn,
    REG_PCSL,
    REG_PCSH,
    REG_PCP,
    REG_IMML,
    REG_IMMH,
    REG_HARDCODED_1
  } reg_type;

  typedef enum {
    REG_NONE,
    REG_XHL,
    REG_YHL,
    REG_SP
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
endpackage
