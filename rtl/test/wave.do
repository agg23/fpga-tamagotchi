onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /jp_tb//bench/cpu_uut/clk
add wave -noupdate /jp_tb//bench/cpu_uut/clk_2x
add wave -noupdate /jp_tb//bench/cpu_uut/reset_n
add wave -noupdate -radix hexadecimal /jp_tb//bench/cpu_uut/rom_addr
add wave -noupdate -radix hexadecimal /jp_tb//bench/cpu_uut/rom_data
add wave -noupdate /jp_tb//bench/cpu_uut/memory_write_en
add wave -noupdate -radix hexadecimal /jp_tb//bench/cpu_uut/memory_addr
add wave -noupdate -radix hexadecimal /jp_tb//bench/cpu_uut/memory_write_data
add wave -noupdate -radix hexadecimal /jp_tb//bench/cpu_uut/memory_read_data
add wave -noupdate /jp_tb//bench/cpu_uut/skip_pc_increment
add wave -noupdate /jp_tb//bench/cpu_uut/decode_skip_pc_increment
add wave -noupdate /jp_tb//bench/cpu_uut/increment_pc
add wave -noupdate -radix hexadecimal /jp_tb//bench/cpu_uut/microcode_start_addr
add wave -noupdate /jp_tb//bench/cpu_uut/decode_cycle_length
add wave -noupdate /jp_tb//bench/cpu_uut/cycle_length
add wave -noupdate -radix hexadecimal /jp_tb//bench/cpu_uut/immed
add wave -noupdate /jp_tb//bench/cpu_uut/current_cycle
add wave -noupdate /jp_tb//bench/cpu_uut/microcode/stage
add wave -noupdate -radix hexadecimal /jp_tb//bench/cpu_uut/microcode/micro_pc
add wave -noupdate -radix hexadecimal /jp_tb//bench/cpu_uut/microcode/instruction
add wave -noupdate /jp_tb//bench/cpu_uut/bus_input_selector
add wave -noupdate /jp_tb//bench/cpu_uut/bus_output_selector
add wave -noupdate /jp_tb//bench/cpu_uut/increment_selector
add wave -noupdate /jp_tb//bench/cpu_uut/alu_op
add wave -noupdate /jp_tb//bench/cpu_uut/alu_zero_in
add wave -noupdate /jp_tb//bench/cpu_uut/alu_carry_in
add wave -noupdate -radix hexadecimal /jp_tb//bench/cpu_uut/temp_a
add wave -noupdate -radix hexadecimal /jp_tb//bench/cpu_uut/temp_b
add wave -noupdate /jp_tb//bench/cpu_uut/alu_decimal_in
add wave -noupdate /jp_tb//bench/cpu_uut/alu_carry_out
add wave -noupdate /jp_tb//bench/cpu_uut/alu_zero_out
add wave -noupdate -radix hexadecimal /jp_tb//bench/cpu_uut/alu_out
add wave -noupdate -radix hexadecimal /jp_tb//bench/cpu_uut/regs/pc
add wave -noupdate -radix hexadecimal /jp_tb//bench/cpu_uut/regs/temp_a
add wave -noupdate -radix hexadecimal /jp_tb//bench/cpu_uut/regs/temp_b
add wave -noupdate -radix hexadecimal /jp_tb//bench/cpu_uut/regs/zero
add wave -noupdate -radix hexadecimal /jp_tb//bench/cpu_uut/regs/carry
add wave -noupdate -radix hexadecimal /jp_tb//bench/cpu_uut/regs/decimal
add wave -noupdate -radix hexadecimal /jp_tb//bench/cpu_uut/regs/np
add wave -noupdate -radix hexadecimal /jp_tb//bench/cpu_uut/regs/a
add wave -noupdate -radix hexadecimal /jp_tb//bench/cpu_uut/regs/b
add wave -noupdate -radix hexadecimal /jp_tb//bench/cpu_uut/regs/x
add wave -noupdate -radix hexadecimal /jp_tb//bench/cpu_uut/regs/y
add wave -noupdate -radix hexadecimal /jp_tb//bench/cpu_uut/regs/sp
add wave -noupdate /jp_tb//bench/cpu_uut/regs/interrupt
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 340
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {40 ps}
