onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /interrupt_tb/bench/cpu_uut/core/clk
add wave -noupdate /interrupt_tb/bench/cpu_uut/core/clk_2x
add wave -noupdate /interrupt_tb/bench/cpu_uut/core/reset_n
add wave -noupdate -radix hexadecimal /interrupt_tb/bench/cpu_uut/core/rom_addr
add wave -noupdate -radix hexadecimal /interrupt_tb/bench/cpu_uut/core/rom_data
add wave -noupdate /interrupt_tb/bench/cpu_uut/core/memory_write_en
add wave -noupdate -radix hexadecimal /interrupt_tb/bench/cpu_uut/core/memory_addr
add wave -noupdate -radix hexadecimal /interrupt_tb/bench/cpu_uut/core/memory_write_data
add wave -noupdate -radix hexadecimal /interrupt_tb/bench/cpu_uut/core/memory_read_data
add wave -noupdate /interrupt_tb/bench/cpu_uut/core/skip_pc_increment
add wave -noupdate /interrupt_tb/bench/cpu_uut/core/decode_skip_pc_increment
add wave -noupdate /interrupt_tb/bench/cpu_uut/core/increment_pc
add wave -noupdate -radix hexadecimal /interrupt_tb/bench/cpu_uut/core/microcode_start_addr
add wave -noupdate /interrupt_tb/bench/cpu_uut/core/decode_cycle_length
add wave -noupdate /interrupt_tb/bench/cpu_uut/core/cycle_length
add wave -noupdate -radix hexadecimal /interrupt_tb/bench/cpu_uut/core/immed
add wave -noupdate /interrupt_tb/bench/cpu_uut/core/current_cycle
add wave -noupdate /interrupt_tb/bench/cpu_uut/core/microcode/stage
add wave -noupdate -radix hexadecimal /interrupt_tb/bench/cpu_uut/core/microcode/micro_pc
add wave -noupdate -radix hexadecimal /interrupt_tb/bench/cpu_uut/core/microcode/instruction
add wave -noupdate /interrupt_tb/bench/cpu_uut/core/bus_input_selector
add wave -noupdate /interrupt_tb/bench/cpu_uut/core/bus_output_selector
add wave -noupdate /interrupt_tb/bench/cpu_uut/core/increment_selector
add wave -noupdate /interrupt_tb/bench/cpu_uut/core/alu_op
add wave -noupdate /interrupt_tb/bench/cpu_uut/core/flag_zero
add wave -noupdate /interrupt_tb/bench/cpu_uut/core/flag_carry
add wave -noupdate /interrupt_tb/bench/cpu_uut/core/flag_decimal
add wave -noupdate /interrupt_tb/bench/cpu_uut/core/flag_interrupt
add wave -noupdate /interrupt_tb/bench/cpu_uut/core/alu_carry_out
add wave -noupdate /interrupt_tb/bench/cpu_uut/core/alu_zero_out
add wave -noupdate -radix hexadecimal /interrupt_tb/bench/cpu_uut/core/alu_out
add wave -noupdate -radix hexadecimal /interrupt_tb/bench/cpu_uut/core/regs/pc
add wave -noupdate -radix hexadecimal /interrupt_tb/bench/cpu_uut/core/regs/temp_a
add wave -noupdate -radix hexadecimal /interrupt_tb/bench/cpu_uut/core/regs/temp_b
add wave -noupdate -radix hexadecimal /interrupt_tb/bench/cpu_uut/core/regs/zero
add wave -noupdate -radix hexadecimal /interrupt_tb/bench/cpu_uut/core/regs/carry
add wave -noupdate -radix hexadecimal /interrupt_tb/bench/cpu_uut/core/regs/decimal
add wave -noupdate -radix hexadecimal /interrupt_tb/bench/cpu_uut/core/regs/np
add wave -noupdate -radix hexadecimal /interrupt_tb/bench/cpu_uut/core/regs/a
add wave -noupdate -radix hexadecimal /interrupt_tb/bench/cpu_uut/core/regs/b
add wave -noupdate -radix hexadecimal /interrupt_tb/bench/cpu_uut/core/regs/x
add wave -noupdate -radix hexadecimal /interrupt_tb/bench/cpu_uut/core/regs/y
add wave -noupdate -radix hexadecimal /interrupt_tb/bench/cpu_uut/core/regs/sp
add wave -noupdate /interrupt_tb/bench/cpu_uut/core/regs/interrupt
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
