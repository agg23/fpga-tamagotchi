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
    REG_IMM
  } reg_type;

  typedef enum {
    CYCLE_NONE,
    CYCLE_REG_FETCH,
    CYCLE_REG_WRITE
  } microcode_cycle;
endpackage
