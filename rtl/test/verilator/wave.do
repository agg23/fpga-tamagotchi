add wave -noupdate /TOP/top/clk
add wave -noupdate /TOP/top/clk_en_32_768khz
add wave -noupdate /TOP/top/clk_en_65_536khz
add wave -noupdate /TOP/top/reset_n
add wave -noupdate -radix hexadecimal -childformat {{{/TOP/top/rom_addr[12]} -radix hexadecimal} {{/TOP/top/rom_addr[11]} -radix hexadecimal} {{/TOP/top/rom_addr[10]} -radix hexadecimal} {{/TOP/top/rom_addr[9]} -radix hexadecimal} {{/TOP/top/rom_addr[8]} -radix hexadecimal} {{/TOP/top/rom_addr[7]} -radix hexadecimal} {{/TOP/top/rom_addr[6]} -radix hexadecimal} {{/TOP/top/rom_addr[5]} -radix hexadecimal} {{/TOP/top/rom_addr[4]} -radix hexadecimal} {{/TOP/top/rom_addr[3]} -radix hexadecimal} {{/TOP/top/rom_addr[2]} -radix hexadecimal} {{/TOP/top/rom_addr[1]} -radix hexadecimal} {{/TOP/top/rom_addr[0]} -radix hexadecimal}} -subitemconfig {{/TOP/top/rom_addr[12]} {-height 15 -radix hexadecimal} {/TOP/top/rom_addr[11]} {-height 15 -radix hexadecimal} {/TOP/top/rom_addr[10]} {-height 15 -radix hexadecimal} {/TOP/top/rom_addr[9]} {-height 15 -radix hexadecimal} {/TOP/top/rom_addr[8]} {-height 15 -radix hexadecimal} {/TOP/top/rom_addr[7]} {-height 15 -radix hexadecimal} {/TOP/top/rom_addr[6]} {-height 15 -radix hexadecimal} {/TOP/top/rom_addr[5]} {-height 15 -radix hexadecimal} {/TOP/top/rom_addr[4]} {-height 15 -radix hexadecimal} {/TOP/top/rom_addr[3]} {-height 15 -radix hexadecimal} {/TOP/top/rom_addr[2]} {-height 15 -radix hexadecimal} {/TOP/top/rom_addr[1]} {-height 15 -radix hexadecimal} {/TOP/top/rom_addr[0]} {-height 15 -radix hexadecimal}} /TOP/top/rom_addr
add wave -noupdate -radix hexadecimal /TOP/top/rom_data
add wave -noupdate -radix hexadecimal /TOP/top/tamagotchi/core/decoder/opcode
add wave -noupdate /TOP/top/tamagotchi/core/skip_pc_increment
add wave -noupdate -radix hexadecimal /TOP/top/tamagotchi/core/decoder/microcode_start_addr
add wave -noupdate /TOP/top/tamagotchi/core/cycle_length
add wave -noupdate -radix hexadecimal /TOP/top/tamagotchi/core/decoder/immed
add wave -noupdate /TOP/top/tamagotchi/core/microcode/current_cycle
add wave -noupdate /TOP/top/tamagotchi/core/microcode/bus_input_selector
add wave -noupdate /TOP/top/tamagotchi/core/microcode/bus_output_selector
add wave -noupdate /TOP/top/tamagotchi/core/microcode/increment_selector
add wave -noupdate /TOP/top/tamagotchi/core/microcode/alu_operation
add wave -noupdate /TOP/top/tamagotchi/core/microcode/stage
add wave -noupdate -radix hexadecimal /TOP/top/tamagotchi/core/microcode/instruction_big_endian
add wave -noupdate -radix hexadecimal /TOP/top/tamagotchi/core/microcode/micro_pc
add wave -noupdate -radix hexadecimal /TOP/top/tamagotchi/core/microcode/instruction
add wave -noupdate /TOP/top/tamagotchi/core/microcode/last_cycle_step
add wave -noupdate /TOP/top/tamagotchi/core/microcode/microcode_tick
add wave -noupdate /TOP/top/tamagotchi/core/microcode/prev_stage
add wave -noupdate /TOP/top/tamagotchi/core/microcode/cycle_second_step
add wave -noupdate -radix hexadecimal /TOP/top/tamagotchi/core/regs/alu
add wave -noupdate /TOP/top/tamagotchi/core/regs/alu_zero
add wave -noupdate /TOP/top/tamagotchi/core/regs/alu_carry
add wave -noupdate -radix hexadecimal /TOP/top/tamagotchi/core/regs/immed
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