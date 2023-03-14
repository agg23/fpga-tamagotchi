onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /savestates_tb/bench/cpu_uut/core/clk
add wave -noupdate /savestates_tb/bench/cpu_uut/core/clk_2x
add wave -noupdate /savestates_tb/bench/cpu_uut/core/reset_n
add wave -noupdate -radix hexadecimal /savestates_tb/bench/cpu_uut/core/rom_addr
add wave -noupdate -radix hexadecimal /savestates_tb/bench/cpu_uut/core/rom_data
add wave -noupdate /savestates_tb/bench/cpu_uut/core/memory_write_en
add wave -noupdate -radix hexadecimal /savestates_tb/bench/cpu_uut/core/memory_addr
add wave -noupdate -radix hexadecimal /savestates_tb/bench/cpu_uut/core/memory_write_data
add wave -noupdate -radix hexadecimal /savestates_tb/bench/cpu_uut/core/memory_read_data
add wave -noupdate /savestates_tb/bench/cpu_uut/core/skip_pc_increment
add wave -noupdate /savestates_tb/bench/cpu_uut/core/decode_skip_pc_increment
add wave -noupdate /savestates_tb/bench/cpu_uut/core/increment_pc
add wave -noupdate -radix hexadecimal /savestates_tb/bench/cpu_uut/core/microcode_start_addr
add wave -noupdate /savestates_tb/bench/cpu_uut/core/decode_cycle_length
add wave -noupdate /savestates_tb/bench/cpu_uut/core/cycle_length
add wave -noupdate -radix hexadecimal /savestates_tb/bench/cpu_uut/core/immed
add wave -noupdate /savestates_tb/bench/cpu_uut/core/current_cycle
add wave -noupdate /savestates_tb/bench/cpu_uut/core/microcode/stage
add wave -noupdate -radix hexadecimal /savestates_tb/bench/cpu_uut/core/microcode/micro_pc
add wave -noupdate -radix hexadecimal /savestates_tb/bench/cpu_uut/core/microcode/instruction
add wave -noupdate /savestates_tb/bench/cpu_uut/core/bus_input_selector
add wave -noupdate /savestates_tb/bench/cpu_uut/core/bus_output_selector
add wave -noupdate /savestates_tb/bench/cpu_uut/core/increment_selector
add wave -noupdate /savestates_tb/bench/cpu_uut/core/alu_op
add wave -noupdate /savestates_tb/bench/cpu_uut/core/flag_zero
add wave -noupdate /savestates_tb/bench/cpu_uut/core/flag_carry
add wave -noupdate /savestates_tb/bench/cpu_uut/core/flag_decimal
add wave -noupdate /savestates_tb/bench/cpu_uut/core/flag_interrupt
add wave -noupdate /savestates_tb/bench/cpu_uut/core/alu_carry_out
add wave -noupdate /savestates_tb/bench/cpu_uut/core/alu_zero_out
add wave -noupdate -radix hexadecimal /savestates_tb/bench/cpu_uut/core/alu_out
add wave -noupdate -radix hexadecimal /savestates_tb/bench/cpu_uut/core/regs/pc
add wave -noupdate -radix hexadecimal /savestates_tb/bench/cpu_uut/core/regs/temp_a
add wave -noupdate -radix hexadecimal /savestates_tb/bench/cpu_uut/core/regs/temp_b
add wave -noupdate -radix hexadecimal /savestates_tb/bench/cpu_uut/core/regs/zero
add wave -noupdate -radix hexadecimal /savestates_tb/bench/cpu_uut/core/regs/carry
add wave -noupdate -radix hexadecimal /savestates_tb/bench/cpu_uut/core/regs/decimal
add wave -noupdate -radix hexadecimal /savestates_tb/bench/cpu_uut/core/regs/np
add wave -noupdate -radix hexadecimal /savestates_tb/bench/cpu_uut/core/regs/a
add wave -noupdate -radix hexadecimal /savestates_tb/bench/cpu_uut/core/regs/b
add wave -noupdate -radix hexadecimal /savestates_tb/bench/cpu_uut/core/regs/x
add wave -noupdate -radix hexadecimal /savestates_tb/bench/cpu_uut/core/regs/y
add wave -noupdate -radix hexadecimal /savestates_tb/bench/cpu_uut/core/regs/sp
add wave -noupdate /savestates_tb/bench/cpu_uut/core/regs/interrupt
add wave -noupdate /savestates_tb/bench/input_k0
add wave -noupdate /savestates_tb/bench/input_k1
add wave -noupdate /savestates_tb/bench/cpu_uut/input_relation_k0
add wave -noupdate /savestates_tb/bench/cpu_uut/input_factor
add wave -noupdate /savestates_tb/bench/cpu_uut/input_k0_mask
add wave -noupdate /savestates_tb/bench/cpu_uut/input_k1_mask
add wave -noupdate -radix hexadecimal /savestates_tb/bench/ss_bus_in
add wave -noupdate -radix hexadecimal /savestates_tb/bench/ss_bus_addr
add wave -noupdate /savestates_tb/bench/ss_bus_wren
add wave -noupdate /savestates_tb/bench/ss_bus_reset_n
add wave -noupdate -radix hexadecimal /savestates_tb/bench/ss_bus_out
add wave -noupdate -radix hexadecimal /savestates_tb/bench/cpu_uut/core/ss_bus_out
add wave -noupdate -radix hexadecimal /savestates_tb/bench/cpu_uut/interrupt/ss_bus_out
add wave -noupdate -radix hexadecimal /savestates_tb/bench/cpu_uut/timers/ss_bus_out
add wave -noupdate -radix hexadecimal /savestates_tb/bench/cpu_uut/input_lines/ss_bus_out
add wave -noupdate -radix hexadecimal /savestates_tb/bench/cpu_uut/video_ram/address_b
add wave -noupdate -radix hexadecimal /savestates_tb/bench/cpu_uut/video_ram/data_b
add wave -noupdate -radix hexadecimal /savestates_tb/bench/cpu_uut/video_ram/q_b
add wave -noupdate -radix hexadecimal /savestates_tb/bench/cpu_uut/video_ram/wren_b
add wave -noupdate -radix hexadecimal /savestates_tb/bench/cpu_uut/ss_video_ram/mem_addr
add wave -noupdate -radix hexadecimal /savestates_tb/bench/cpu_uut/ss_video_ram/mem_current_data
add wave -noupdate -radix hexadecimal /savestates_tb/bench/cpu_uut/ss_video_ram/mem_new_data
add wave -noupdate -radix hexadecimal /savestates_tb/bench/cpu_uut/ss_video_ram/base_ss_address
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
