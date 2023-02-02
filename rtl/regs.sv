import types::*;

module regs (
    input wire clk,
    input microcode_cycle current_cycle,

    input reg_type bus_input_selector,
    input reg_type bus_output_selector,
    input reg_inc_type increment_selector,

    input wire increment_pc,
    input wire transfer_np,

    input wire [3:0] alu,
    input wire alu_zero,
    input wire alu_carry,
    input wire [7:0] immed,

    output reg memory_write_en,
    output wire [11:0] memory_addr,
    output reg [3:0] memory_write_data,
    input wire [3:0] memory_read_data,

    output reg [12:0] pc = 0,
    output reg [ 3:0] temp_a,
    output reg [ 3:0] temp_b,

    output reg carry,
    output reg decimal
);
  // Registers
  reg [4:0] np;

  reg [3:0] a;
  reg [3:0] b;

  reg [11:0] x;
  reg [11:0] y;

  reg [7:0] sp;

  // Flags
  reg zero;
  reg interrupt;

  wire [3:0] flags_in = {interrupt, decimal, zero, carry};

  // Increment
  wire [7:0] x_inc = x[7:0] + 1;
  wire [7:0] y_inc = y[7:0] + 1;
  wire [7:0] sp_inc = sp + 1;
  wire [7:0] sp_dec = sp - 1;

  // Bus
  wire [3:0] bus_input;

  wire use_bus_input_memory_addr;
  wire [11:0] bus_input_memory_addr;
  reg [11:0] bus_output_memory_addr;

  assign memory_addr = use_bus_input_memory_addr ? bus_input_memory_addr : bus_output_memory_addr;

  reg_mux bus_input_mux (
      .selector(bus_input_selector),

      .alu  (alu),
      .flags(flags_in),

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
    reg_type modified_selector;

    if (current_cycle != CYCLE_REG_WRITE) begin
      memory_write_en <= 0;
    end

    if (bus_output_selector == REG_IMM_ADDR_L || bus_output_selector == REG_IMM_ADDR_H || bus_output_selector == REG_IMM_ADDR_P) begin
      modified_selector = imm_addressed_reg(bus_output_selector, immed[5:0]);
    end else begin
      modified_selector = bus_output_selector;
    end

    // TODO: Handle setting PC
    // TODO: Handle NBP and NPP

    // Some registers are set only on WRITE cycle, others do stuff on other cycles
    casex ({
      modified_selector, current_cycle
    })
      {
        REG_ALU, 2'hX
      }, {
        REG_ALU_WITH_FLAGS, 2'hX
      }, {
        REG_IMML, 2'hX
      }, {
        REG_IMMH, 2'hX
      } : begin
        // Do nothing, these are invalid write targets
      end

      {REG_FLAGS, CYCLE_REG_WRITE} : {interrupt, decimal, zero, carry} <= bus_input;

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
        REG_MSP_DEC, CYCLE_REG_FETCH
      } : begin
        bus_output_memory_addr <= sp_dec;
        memory_write_data <= bus_input;
        memory_write_en <= 1;
      end
      {
        REG_Mn, CYCLE_REG_FETCH
      } : begin
        bus_output_memory_addr <= immed[3:0];
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

      {REG_PCSL, CYCLE_REG_WRITE} : pc[3:0] <= bus_input;
      {REG_PCSH, CYCLE_REG_WRITE} : pc[7:4] <= bus_input;
      {REG_PCP, CYCLE_REG_WRITE} :  pc[11:8] <= bus_input;

      {REG_NPP, CYCLE_REG_WRITE} : np[3:0] <= bus_input;
      {REG_NBP, CYCLE_REG_WRITE} : np[4] <= bus_input[0];
    endcase

    if (bus_input_selector == REG_ALU_WITH_FLAGS && current_cycle == CYCLE_REG_WRITE) begin
      // On write, using value from REG_ALU_WITH_FLAGS, set flags
      carry <= alu_carry;
      zero  <= alu_zero;
    end

    // PC increment
    if (transfer_np) begin
      pc[12:8] <= np;
    end else if (increment_pc) begin
      pc[11:0] <= pc[11:0] + 1;
    end
  end

  // Post-increment
  always @(posedge clk) begin
    if (current_cycle == CYCLE_REG_WRITE) begin
      // Increment any configured post-increment reg
      case (increment_selector)
        REG_NONE: begin
          // Do nothing
        end
        REG_XHL: x[7:0] <= x_inc;
        REG_YHL: y[7:0] <= y_inc;
        REG_SP_INC: sp <= sp_inc;
        REG_SP_DEC: sp <= sp_dec;
      endcase
    end
  end
endmodule
