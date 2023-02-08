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
    input wire [3:0] memory_read_data
);
  // Microcode
  reg skip_pc_increment;
  wire decode_skip_pc_increment;
  wire increment_pc;

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

  wire alu_zero_in;
  wire alu_carry_in;

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

      .zero (alu_zero_in),
      .carry(alu_carry_in),

      // Control
      .increment_pc(increment_pc),

      .microcode_start_addr(microcode_start_addr),
      .cycle_length(cycle_length),

      // Bus
      .current_cycle(current_cycle),

      .bus_input_selector(bus_input_selector),
      .bus_output_selector(bus_output_selector),
      .increment_selector(increment_selector),
      .alu_operation(alu_op)
  );

  wire [3:0] temp_a;
  wire [3:0] temp_b;

  wire alu_decimal_in;
  wire alu_carry_out;
  wire alu_zero_out;

  wire [3:0] alu_out;

  alu alu (
      .op(alu_op),

      .temp_a(temp_a),
      .temp_b(temp_b),

      .flag_carry_in  (alu_carry_in),
      .flag_decimal_in(alu_decimal_in),

      .out(alu_out),
      .flag_carry_out(alu_carry_out),
      .flag_zero_out(alu_zero_out)
  );

  regs regs (
      .clk(clk),

      .current_cycle(current_cycle),

      .bus_input_selector (bus_input_selector),
      .bus_output_selector(bus_output_selector),
      .increment_selector (increment_selector),

      .increment_pc(increment_pc && ~skip_pc_increment),
      // TODO
      .transfer_np (1'b0),

      .alu(alu_out),
      .alu_zero(alu_zero_out),
      .alu_carry(alu_carry_out),
      .immed(immed),

      .memory_write_en(memory_write_en),
      .memory_addr(memory_addr),
      .memory_write_data(memory_write_data),
      .memory_read_data(memory_read_data),

      .pc(rom_addr),
      .temp_a(temp_a),
      .temp_b(temp_b),

      .zero(alu_zero_in),
      .carry(alu_carry_in),
      .decimal(alu_decimal_in)
  );
endmodule
