import types::*;

module cpu (
    input wire clk,
    input wire clk_2x,

    input wire reset_n,

    output wire [12:0] rom_addr,
    input  wire [11:0] rom_data,

    output reg memory_write_en,
    output wire [11:0] memory_addr,
    output reg [3:0] memory_write_data,
    input wire [3:0] memory_read_data,

    input wire [14:0] interrupt_req
);
  // Microcode
  reg skip_pc_increment;
  wire decode_skip_pc_increment;
  wire increment_pc;
  wire reset_np;

  wire [6:0] microcode_start_addr;
  instr_length decode_cycle_length;
  instr_length cycle_length;

  wire [7:0] immed;

  decode decoder (
      .opcode(rom_data),

      .skip_pc_increment(decode_skip_pc_increment),

      .microcode_start_addr(microcode_start_addr),
      .cycle_length(decode_cycle_length),

      .immed(immed)
  );

  microcode_cycle current_cycle;

  reg_type bus_input_selector;
  reg_type bus_output_selector;
  reg_inc_type increment_selector;

  alu_op alu_op;

  wire flag_zero;
  wire flag_carry;
  wire flag_decimal;
  wire flag_interrupt;

  wire performing_interrupt;
  wire [3:0] interrupt_address;

  always @(posedge clk_2x) begin
    if (current_cycle == CYCLE_NONE) begin
      skip_pc_increment <= decode_skip_pc_increment;
      cycle_length <= decode_cycle_length;
    end
  end

  microcode microcode (
      .clk(clk),
      .clk_2x(clk_2x),

      .reset_n(reset_n),

      .zero(flag_zero),
      .carry(flag_carry),
      .interrupt(flag_interrupt),

      // Control
      .increment_pc(increment_pc),
      .reset_np(reset_np),

      .microcode_start_addr(microcode_start_addr),
      .cycle_length(cycle_length),

      // Interrupt
      .interrupt_req(interrupt_req),
      .performing_interrupt(performing_interrupt),
      .interrupt_address(interrupt_address),

      // Bus
      .current_cycle(current_cycle),

      .bus_input_selector(bus_input_selector),
      .bus_output_selector(bus_output_selector),
      .increment_selector(increment_selector),
      .alu_operation(alu_op)
  );

  wire [3:0] temp_a;
  wire [3:0] temp_b;

  wire alu_carry_out;
  wire alu_zero_out;

  wire [3:0] alu_out;

  alu alu (
      .op(alu_op),

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

      .reset_n(reset_n),

      .current_cycle(current_cycle),

      .bus_input_selector (bus_input_selector),
      .bus_output_selector(bus_output_selector),
      .increment_selector (increment_selector),

      .increment_pc(increment_pc && ~skip_pc_increment),
      .reset_np(reset_np),

      .alu(alu_out),
      .alu_zero(alu_zero_out),
      .alu_carry(alu_carry_out),
      // Offset by 1, since 0 index is reset vector
      .immed(performing_interrupt ? {4'b0, interrupt_address + 1'b1} : immed),

      .memory_write_en(memory_write_en),
      .memory_addr(memory_addr),
      .memory_write_data(memory_write_data),
      .memory_read_data(memory_read_data),

      .pc(rom_addr),
      .temp_a(temp_a),
      .temp_b(temp_b),

      .zero(flag_zero),
      .carry(flag_carry),
      .decimal(flag_decimal),
      .interrupt(flag_interrupt)
  );
endmodule
