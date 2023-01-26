import types::*;

module regs (
    input wire clk,
    input microcode_cycle current_cycle,

    input reg_type bus_input_selector,
    input reg_type bus_output_selector,

    input wire [3:0] alu,
    input wire [3:0] immed,

    output reg memory_write_en,
    output wire [11:0] memory_addr,
    output reg [3:0] memory_write_data,
    input wire [3:0] memory_read_data
);
  // Registers
  reg [3:0] a;
  reg [3:0] b;

  reg [3:0] temp_a;
  reg [3:0] temp_b;

  reg [11:0] x;
  reg [11:0] y;

  reg [7:0] sp;

  wire [3:0] bus_input;

  wire use_bus_input_memory_addr;
  wire [11:0] bus_input_memory_addr;
  reg [11:0] bus_output_memory_addr;

  assign memory_addr = use_bus_input_memory_addr ? bus_input_memory_addr : bus_output_memory_addr;

  reg_mux bus_input_mux (
      .selector(bus_input_selector),

      .alu(alu),

      .a(a),
      .b(b),

      .temp_a(temp_a),
      .temp_b(temp_b),

      .x(x),
      .y(y),

      .sp(sp),

      .immed(immed),

      .memory_read_data(memory_read_data),
      .use_memory(use_bus_input_memory_addr),
      .memory_addr(bus_input_memory_addr),
      .out(bus_input)
  );

  // Write bus output
  always @(posedge clk) begin
    if (current_cycle != CYCLE_REG_WRITE) begin
      memory_write_en <= 0;
    end

    // Some registers are set only on WRITE cycle, others do stuff on other cycles
    casex ({
      bus_output_selector, current_cycle
    })
      {
        REG_ALU, 2'hX
      }, {
        REG_IMM, 2'hX
      } : begin
        // Do nothing, these are invalid write targets
      end

      // Grab address and data in fetch cycle
      {
        REG_MX, CYCLE_REG_FETCH
      } : begin
        bus_output_memory_addr <= x;
        memory_write_data <= bus_input;
        memory_write_en <= 1;
      end
      {
        REG_MY, CYCLE_REG_FETCH
      } : begin
        bus_output_memory_addr <= y;
        memory_write_data <= bus_input;
        memory_write_en <= 1;
      end
      {
        REG_MSP, CYCLE_REG_FETCH
      } : begin
        bus_output_memory_addr <= sp;
        memory_write_data <= bus_input;
        memory_write_en <= 1;
      end
      {
        REG_Mn, CYCLE_REG_FETCH
      } : begin
        bus_output_memory_addr <= immed;
        memory_write_data <= bus_input;
        memory_write_en <= 1;
      end

      {REG_A, CYCLE_REG_WRITE} : a <= bus_input;
      {REG_B, CYCLE_REG_WRITE} : b <= bus_input;

      {REG_TEMPA, CYCLE_REG_WRITE} : temp_a <= bus_input;
      {REG_TEMPB, CYCLE_REG_WRITE} : temp_b <= bus_input;

      {REG_XL, CYCLE_REG_WRITE} : x[3:0] <= bus_input;
      {REG_XH, CYCLE_REG_WRITE} : x[7:4] <= bus_input;
      {REG_XP, CYCLE_REG_WRITE} : x[11:8] <= bus_input;

      {REG_YL, CYCLE_REG_WRITE} : y[3:0] <= bus_input;
      {REG_YH, CYCLE_REG_WRITE} : y[7:4] <= bus_input;
      {REG_YP, CYCLE_REG_WRITE} : y[11:8] <= bus_input;

      {REG_SPL, CYCLE_REG_WRITE} : sp[3:0] <= bus_input;
      {REG_SPH, CYCLE_REG_WRITE} : sp[7:4] <= bus_input;
    endcase
  end
endmodule
