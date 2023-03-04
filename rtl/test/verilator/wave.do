virtual type {CYCLE_NONE CYCLE_REG_FETCH CYCLE_REG_WRITE} microcode_cycle
virtual function {(microcode_cycle)/TOP/top/tamagotchi/core/microcode/current_cycle} current_cycle_str

virtual type {REG_NONE REG_XHL REG_YHL REG_SP_INC REG_SP_DEC REG_PC} reg_inc_type
virtual function {(reg_inc_type)/TOP/top/tamagotchi/core/microcode/increment_selector} increment_selector_str

virtual type {REG_FLAGS REG_A REG_B REG_TEMPA REG_TEMPB REG_XL REG_XH REG_XP REG_YL REG_YH REG_YP REG_SPL REG_SPH REG_MX REG_MY REG_MSP REG_MSP_INC REG_MSP_DEC REG_Mn REG_PCSL REG_PCSH REG_PCP REG_PCP_EARLY REG_NBP REG_NPP REG_IMML REG_IMMH REG_HARDCODED_1 REG_IMM_ADDR_L REG_IMM_ADDR_H REG_IMM_ADDR_P REG_SETPC REG_CALLEND_ZERO_PCP REG_CALLEND_SET_PCP REG_JPBAEND REG_STARTINTERRUPT REG_PCP_INC REG_PCSH_INC REG_ALU REG_ALU_WITH_FLAGS} reg_type
virtual function {(reg_type)/TOP/top/tamagotchi/core/microcode/bus_input_selector} bus_input_selector_str
virtual function {(reg_type)/TOP/top/tamagotchi/core/microcode/bus_output_selector} bus_output_selector_str

virtual type {ALU_ADD ALU_ADD_NO_DEC ALU_ADC ALU_ADC_NO_DEC ALU_SUB ALU_SUB_NO_DEC ALU_SBC ALU_AND ALU_OR ALU_XOR ALU_CP ALU_RRC ALU_RLC} alu_op
virtual function {(alu_op)/TOP/top/tamagotchi/core/microcode/alu_operation} alu_operation_str

virtual type {CYCLE5 CYCLE7 CYCLE12} instr_length
virtual function {(instr_length)/TOP/top/tamagotchi/core/cycle_length} cycle_length_str

virtual type {DECODE STEP1 STEP1_2 STEP2 STEP2_2 STEP3 STEP3_2 STEP4 STEP5 STEP5_2 STEP6 STEP6_2} microcode_stage
virtual function {(microcode_stage)/TOP/top/tamagotchi/core/microcode/stage} stage_str
virtual function {(microcode_stage)/TOP/top/tamagotchi/core/microcode/prev_stage} prev_stage_str

virtual type {JP_s RETD_e JP_C_s JP_NC_s CALL_s CALZ_s JP_Z_s JP_NZ_s LD_Y_e LBPX_MX_e ADC_XH_i ADC_XL_i ADC_YH_i ADC_YL_i CP_XH_i CP_XL_i CP_YH_i CP_YL_i ADD_r_q ADC_r_q SUB_r_q SBC_r_q AND_r_q OR_r_q XOR_r_q RLC_r LD_X_e ADD_r_i ADC_r_i AND_r_i OR_r_i XOR_r_i SBC_r_i FAN_r_i CP_r_i LD_r_i PSET_p LDPX_MX_i LDPY_MY_i LD_XP_r LD_XH_r LD_XL_r RRC_r LD_YP_r LD_YH_r LD_YL_r LD_r_XP LD_r_XH LD_r_XL LD_r_YP LD_r_YH LD_r_YL LD_r_q LDPX_r_q LDPY_r_q CP_r_q FAN_r_q ACPX_MX_r ACPY_MY_r SCPX_MX_r SCPY_MY_r SET_F_i RST_F_i INC_Mn DEC_Mn LD_Mn_A LD_Mn_B LD_A_Mn LD_B_Mn PUSH_r PUSH_XP PUSH_XH PUSH_XL PUSH_YP PUSH_YH PUSH_YL PUSH_F DEC_SP POP_r POP_XP POP_XH POP_XL POP_YP POP_YH POP_YL POP_F INC_SP RETS RET LD_SPH_r LD_r_SPH JPBA LD_SPL_r LD_r_SPL HALT SLP NOP5 NOP7} opcode_defs
virtual function {(opcode_defs)/TOP/top/tamagotchi/core/decoder/microcode_start_addr} opcode_str

add wave -noupdate /TOP/top/clk
add wave -noupdate /TOP/top/clk_en_32_768khz
add wave -noupdate /TOP/top/clk_en_65_536khz
add wave -noupdate /TOP/top/reset_n
add wave -noupdate -radix hexadecimal -childformat {{{/TOP/top/rom_addr[12]} -radix hexadecimal} {{/TOP/top/rom_addr[11]} -radix hexadecimal} {{/TOP/top/rom_addr[10]} -radix hexadecimal} {{/TOP/top/rom_addr[9]} -radix hexadecimal} {{/TOP/top/rom_addr[8]} -radix hexadecimal} {{/TOP/top/rom_addr[7]} -radix hexadecimal} {{/TOP/top/rom_addr[6]} -radix hexadecimal} {{/TOP/top/rom_addr[5]} -radix hexadecimal} {{/TOP/top/rom_addr[4]} -radix hexadecimal} {{/TOP/top/rom_addr[3]} -radix hexadecimal} {{/TOP/top/rom_addr[2]} -radix hexadecimal} {{/TOP/top/rom_addr[1]} -radix hexadecimal} {{/TOP/top/rom_addr[0]} -radix hexadecimal}} -subitemconfig {{/TOP/top/rom_addr[12]} {-height 15 -radix hexadecimal} {/TOP/top/rom_addr[11]} {-height 15 -radix hexadecimal} {/TOP/top/rom_addr[10]} {-height 15 -radix hexadecimal} {/TOP/top/rom_addr[9]} {-height 15 -radix hexadecimal} {/TOP/top/rom_addr[8]} {-height 15 -radix hexadecimal} {/TOP/top/rom_addr[7]} {-height 15 -radix hexadecimal} {/TOP/top/rom_addr[6]} {-height 15 -radix hexadecimal} {/TOP/top/rom_addr[5]} {-height 15 -radix hexadecimal} {/TOP/top/rom_addr[4]} {-height 15 -radix hexadecimal} {/TOP/top/rom_addr[3]} {-height 15 -radix hexadecimal} {/TOP/top/rom_addr[2]} {-height 15 -radix hexadecimal} {/TOP/top/rom_addr[1]} {-height 15 -radix hexadecimal} {/TOP/top/rom_addr[0]} {-height 15 -radix hexadecimal}} /TOP/top/rom_addr
add wave -noupdate -radix hexadecimal /TOP/top/rom_data
add wave -noupdate /TOP/top/tamagotchi/core/decoder/opcode_str
add wave -noupdate /TOP/top/tamagotchi/core/microcode/halt
add wave -noupdate -radix hexadecimal /TOP/top/tamagotchi/core/decoder/opcode
add wave -noupdate /TOP/top/tamagotchi/core/skip_pc_increment
add wave -noupdate -radix hexadecimal /TOP/top/tamagotchi/core/decoder/microcode_start_addr
add wave -noupdate /TOP/top/tamagotchi/core/cycle_length_str
add wave -noupdate -radix hexadecimal /TOP/top/tamagotchi/core/decoder/immed
add wave -noupdate /TOP/top/tamagotchi/core/microcode/current_cycle_str
add wave -noupdate /TOP/top/tamagotchi/core/microcode/bus_input_selector_str
add wave -noupdate /TOP/top/tamagotchi/core/microcode/bus_output_selector_str
add wave -noupdate /TOP/top/tamagotchi/core/microcode/increment_selector_str
add wave -noupdate /TOP/top/tamagotchi/core/microcode/alu_operation_str
add wave -noupdate /TOP/top/tamagotchi/core/microcode/stage_str
add wave -noupdate -radix hexadecimal /TOP/top/tamagotchi/core/microcode/instruction_big_endian
add wave -noupdate -radix hexadecimal /TOP/top/tamagotchi/core/microcode/micro_pc
add wave -noupdate -radix hexadecimal /TOP/top/tamagotchi/core/microcode/instruction
add wave -noupdate /TOP/top/tamagotchi/core/microcode/last_cycle_step
add wave -noupdate /TOP/top/tamagotchi/core/microcode/microcode_tick
add wave -noupdate /TOP/top/tamagotchi/core/microcode/prev_stage_str
add wave -noupdate /TOP/top/tamagotchi/core/microcode/cycle_second_step
add wave -noupdate -radix hexadecimal /TOP/top/tamagotchi/core/regs/alu
add wave -noupdate /TOP/top/tamagotchi/core/regs/alu_zero
add wave -noupdate /TOP/top/tamagotchi/core/regs/alu_carry
add wave -noupdate /TOP/top/tamagotchi/core/regs/memory_write_en
add wave -noupdate -radix hexadecimal /TOP/top/tamagotchi/core/regs/memory_addr
add wave -noupdate -radix hexadecimal /TOP/top/tamagotchi/core/regs/memory_write_data
add wave -noupdate -radix hexadecimal /TOP/top/tamagotchi/core/regs/memory_read_data
add wave -noupdate -radix hexadecimal /TOP/top/tamagotchi/core/regs/pc
add wave -noupdate -radix hexadecimal /TOP/top/tamagotchi/core/regs/temp_a
add wave -noupdate -radix hexadecimal /TOP/top/tamagotchi/core/regs/temp_b
add wave -noupdate -radix hexadecimal /TOP/top/tamagotchi/core/regs/np
add wave -noupdate -radix hexadecimal /TOP/top/tamagotchi/core/regs/a
add wave -noupdate -radix hexadecimal /TOP/top/tamagotchi/core/regs/b
add wave -noupdate -radix hexadecimal /TOP/top/tamagotchi/core/regs/x
add wave -noupdate -radix hexadecimal /TOP/top/tamagotchi/core/regs/y
add wave -noupdate -radix hexadecimal /TOP/top/tamagotchi/core/regs/sp
add wave -noupdate -radix hexadecimal /TOP/top/tamagotchi/core/regs/carry
add wave -noupdate /TOP/top/tamagotchi/core/regs/zero
add wave -noupdate -radix hexadecimal /TOP/top/tamagotchi/core/regs/decimal
add wave -noupdate /TOP/top/tamagotchi/core/regs/interrupt
add wave -noupdate -radix hexadecimal /TOP/top/tamagotchi/core/regs/flags_in
add wave -noupdate -radix hexadecimal /TOP/top/tamagotchi/core/regs/x_inc
add wave -noupdate -radix hexadecimal /TOP/top/tamagotchi/core/regs/y_inc
add wave -noupdate -radix hexadecimal /TOP/top/tamagotchi/core/regs/sp_inc
add wave -noupdate -radix hexadecimal /TOP/top/tamagotchi/core/regs/sp_dec
add wave -noupdate /TOP/top/tamagotchi/interrupt/interrupt_req