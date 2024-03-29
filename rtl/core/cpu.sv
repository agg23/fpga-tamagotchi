import types::*;

module cpu (
    input wire clk,
    input wire clk_en,
    input wire clk_2x_en,

    input wire reset,

    output wire [12:0] rom_addr,
    input  wire [11:0] rom_data,

    output wire memory_write_en,
    output wire memory_read_en,
    output wire [11:0] memory_addr,
    output wire [3:0] memory_write_data,
    input wire [3:0] memory_read_data,

    input wire [14:0] interrupt_req,

    // Savestates
    input wire [31:0] ss_bus_in,
    input wire [7:0] ss_bus_addr,
    input wire ss_bus_wren,
    input wire ss_bus_reset,
    output wire [31:0] ss_bus_out,

    output wire ss_ready
);
  // Microcode
  wire skip_pc_increment;
  wire increment_pc;
  wire disable_interrupt;
  wire reset_np;

  wire [6:0] microcode_start_addr;
  instr_length cycle_length;
  microcode_cycle current_cycle;
  wire is_last_cycle_step;

  wire [7:0] decode_immed;

  decode decoder (
      .clk(clk),
      .clk_2x_en(is_last_cycle_step && clk_en),

      .opcode(rom_data),

      .skip_pc_increment(skip_pc_increment),

      .microcode_start_addr(microcode_start_addr),
      .cycle_length(cycle_length),
      .disable_interrupt(disable_interrupt),

      .immed(decode_immed)
  );

  reg_type bus_input_selector;
  reg_type bus_output_selector;
  reg_inc_type increment_selector;

  alu_op alu_operation;

  wire flag_zero;
  wire flag_carry;
  wire flag_decimal;
  wire flag_interrupt;

  wire performing_interrupt;
  wire [3:0] interrupt_address;

  wire internal_memory_read_en;
  wire override_memory_read_en;

  assign memory_read_en = override_memory_read_en | internal_memory_read_en;

  // Offset by 1, since 0 index is reset vector
  wire [7:0] immed = performing_interrupt ? {4'b0, interrupt_address + 1'b1} : decode_immed;

  microcode microcode (
      .clk(clk),
      .clk_en(clk_en),
      .clk_2x_en(clk_2x_en),

      .reset(reset),

      .zero(flag_zero),
      .carry(flag_carry),
      .interrupt(flag_interrupt),
      .immed(immed),

      // Control
      .increment_pc(increment_pc),
      .reset_np(reset_np),

      .disable_interrupt(disable_interrupt),
      .microcode_start_addr(microcode_start_addr),
      .cycle_length(cycle_length),

      // Interrupt
      .interrupt_req(interrupt_req),
      .performing_interrupt(performing_interrupt),
      .interrupt_address(interrupt_address),

      // Bus
      .current_cycle(current_cycle),
      .is_last_cycle_step(is_last_cycle_step),

      .bus_input_selector(bus_input_selector),
      .bus_output_selector(bus_output_selector),
      .increment_selector(increment_selector),
      .alu_operation(alu_operation),

      .override_memory_read_en(override_memory_read_en),

      .ss_ready(ss_ready)
  );

  wire [3:0] temp_a;
  wire [3:0] temp_b;

  wire alu_carry_out;
  wire alu_zero_out;

  wire [3:0] alu_out;

  alu alu (
      .op(alu_operation),

      .temp_a(temp_a),
      .temp_b(temp_b),

      .flag_carry_in  (flag_carry),
      .flag_decimal_in(flag_decimal),

      .out(alu_out),
      .flag_carry_out(alu_carry_out),
      .flag_zero_out(alu_zero_out)
  );

  regs regs (
      .clk(clk),
      .clk_en(clk_en),
      .clk_2x_en(clk_2x_en),

      .reset(reset),

      .current_cycle(current_cycle),

      .bus_input_selector (bus_input_selector),
      .bus_output_selector(bus_output_selector),
      .increment_selector (increment_selector),

      .increment_pc(increment_pc && ~skip_pc_increment),
      .reset_np(reset_np),

      .alu(alu_out),
      .alu_zero(alu_zero_out),
      .alu_carry(alu_carry_out),
      .immed(immed),

      .memory_write_en(memory_write_en),
      .memory_read_en(internal_memory_read_en),
      .memory_addr(memory_addr),
      .memory_write_data(memory_write_data),
      .memory_read_data(memory_read_data),

      .pc(rom_addr),
      .temp_a(temp_a),
      .temp_b(temp_b),

      .zero(flag_zero),
      .carry(flag_carry),
      .decimal(flag_decimal),
      .interrupt(flag_interrupt),

      // Savestates
      .ss_bus_in(ss_bus_in),
      .ss_bus_addr(ss_bus_addr),
      .ss_bus_wren(ss_bus_wren),
      .ss_bus_reset(ss_bus_reset),
      .ss_bus_out(ss_bus_out)
  );
endmodule
