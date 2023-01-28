import types::*;

module cpu (
    input wire clk
);

  reg [11:0] opcode = 0;

  // Microcode
  wire skip_pc_increment;

  wire [6:0] microcode_start_addr;
  instr_length cycle_length;

  wire [7:0] immed;

  decode decoder (
      .opcode(opcode),

      .skip_pc_increment(skip_pc_increment),

      .microcode_start_addr(microcode_start_addr),
      .cycle_length(cycle_length),

      .immed(immed)
  );

  microcode_cycle current_cycle;

  reg_type bus_input_selector;
  reg_type bus_output_selector;
  reg_inc_type increment_selector;

  microcode microcode (
      .clk(clk),

      // Control
      .skip_pc_increment(skip_pc_increment),

      .microcode_start_addr(microcode_start_addr),
      .cycle_length(cycle_length),

      // Bus
      .current_cycle(current_cycle),

      .bus_input_selector (bus_input_selector),
      .bus_output_selector(bus_output_selector),
      .increment_selector (increment_selector)
  );

  wire memory_write_en;
  wire [11:0] memory_addr;
  wire [3:0] memory_write_data;

  regs regs (
      .clk(clk),

      .current_cycle(current_cycle),

      .bus_input_selector (bus_input_selector),
      .bus_output_selector(bus_output_selector),
      .increment_selector (increment_selector),

      // TODO
      .alu(4'b0),
      .alu_zero(1'b0),
      .alu_carry(1'b0),
      .immed(immed),

      // TODO
      .memory_write_en(memory_write_en),
      .memory_addr(memory_addr),
      .memory_write_data(memory_write_data),
      .memory_read_data(4'b0)
  );

endmodule
