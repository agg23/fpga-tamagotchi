import types::*;
import ss_addresses::*;

module regs (
    input wire clk,
    input wire clk_en,
    input wire clk_2x_en,

    input microcode_cycle current_cycle,

    input wire reset,

    input reg_type bus_input_selector,
    input reg_type bus_output_selector,
    input reg_inc_type increment_selector,

    input wire increment_pc,
    input wire reset_np,

    input wire [3:0] alu,
    input wire alu_zero,
    input wire alu_carry,
    input wire [7:0] immed,

    output reg memory_write_en,
    output wire memory_read_en,
    output wire [11:0] memory_addr,
    output reg [3:0] memory_write_data,
    input wire [3:0] memory_read_data,

    // Start at page 1
    output reg [12:0] pc,
    output reg [ 3:0] temp_a,
    output reg [ 3:0] temp_b,

    // Flags
    output reg zero,
    output reg carry,
    output reg decimal,
    output reg interrupt = 0,

    // Savestates
    input wire [31:0] ss_bus_in,
    input wire [7:0] ss_bus_addr,
    input wire ss_bus_wren,
    input wire ss_bus_reset,
    output wire [31:0] ss_bus_out
);
  // Registers
  // Start at page 1
  reg [4:0] np;

  reg [3:0] a;
  reg [3:0] b;

  reg [11:0] x;
  reg [11:0] y;

  reg [7:0] sp;

  // Flags
  wire [3:0] flags_in = {interrupt, decimal, zero, carry};

  // Increment
  wire [11:0] pc_inc = pc[11:0] + 12'h1;
  wire [7:0] x_inc = x[7:0] + 8'h1;
  wire [7:0] y_inc = y[7:0] + 8'h1;
  wire [7:0] sp_inc = sp + 8'h1;
  wire [7:0] sp_dec = sp - 8'h1;

  // Bus
  wire use_bus_input_memory_addr;
  wire [11:0] bus_input_memory_addr;
  reg [11:0] bus_output_memory_addr;

  assign memory_addr = use_bus_input_memory_addr ? bus_input_memory_addr : bus_output_memory_addr;

  assign memory_read_en = use_bus_input_memory_addr && current_cycle == CYCLE_REG_FETCH;

  wire [3:0] reg_bus_input;
  wire [3:0] bus_input = use_bus_input_memory_addr ? memory_read_data : reg_bus_input;

  wire [31:0] ss_current_data1 = {2'b0, np, pc, a, b, interrupt, decimal, zero, carry};
  wire [31:0] ss_current_data2 = {x, y, sp};

  wire [31:0] ss_new_data1;
  wire [31:0] ss_new_data2;

  wire [31:0] ss_bus_out1;
  wire [31:0] ss_bus_out2;

  assign ss_bus_out = ss_bus_out1 | ss_bus_out2;

  bus_connector #(
      .ADDRESS(SS_REGS1),
      .DEFAULT_VALUE({2'b0, 5'h01, 13'h0_1_00, 12'b0})
  ) ss1 (
      .clk(clk),

      .bus_in(ss_bus_in),
      .bus_addr(ss_bus_addr),
      .bus_wren(ss_bus_wren),
      .bus_reset(ss_bus_reset),
      .bus_out(ss_bus_out1),

      .current_data(ss_current_data1),
      .new_data(ss_new_data1)
  );

  bus_connector #(
      .ADDRESS(SS_REGS2)
  ) ss2 (
      .clk(clk),

      .bus_in(ss_bus_in),
      .bus_addr(ss_bus_addr),
      .bus_wren(ss_bus_wren),
      .bus_reset(ss_bus_reset),
      .bus_out(ss_bus_out2),

      .current_data(ss_current_data2),
      .new_data(ss_new_data2)
  );

  reg_mux bus_input_mux (
      .clk(clk),
      .clk_2x_en(clk_2x_en),

      .is_fetch(current_cycle == CYCLE_REG_FETCH),

      .selector(bus_input_selector),

      .pc(pc),
      .pc_inc(pc_inc),

      .alu  (alu),
      .flags(flags_in),

      .a(a),
      .b(b),

      .temp_a(temp_a),
      .temp_b(temp_b),

      .x(x),
      .y(y),

      .sp(sp),
      .sp_inc(sp_inc),

      .immed(immed),

      .out(reg_bus_input),

      .use_memory (use_bus_input_memory_addr),
      .memory_addr(bus_input_memory_addr)
  );

  // Write bus output
  always @(posedge clk) begin
    if (reset) begin
      {np, pc, a, b, interrupt, decimal, zero, carry} <= ss_new_data1[29:0];
      {x, y, sp} <= ss_new_data2;

      memory_write_en <= 0;
      bus_output_memory_addr <= 0;
    end else if (clk_en) begin
      if (current_cycle != CYCLE_REG_WRITE) begin
        memory_write_en <= 0;
      end

      // REG_IMM_ADDR_L-P is handled in microcode to remove comb logic from mux

      // Some registers are set only on WRITE cycle, others do stuff on other cycles
      casex ({
        bus_output_selector, current_cycle
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

        // Special cases
        // PC is set in fetch, instead of write
        {REG_PCP_EARLY, CYCLE_REG_FETCH} : pc[11:8] <= bus_input;

        {REG_SETPC, CYCLE_REG_FETCH} : pc <= {np, immed};
        {
          REG_STARTINTERRUPT, CYCLE_REG_WRITE
        } : begin
          bus_output_memory_addr <= sp_dec;
          memory_write_data <= bus_input;
          memory_write_en <= 1;

          interrupt <= 0;
        end
        {
          REG_CALLEND_ZERO_PCP, CYCLE_REG_FETCH
        } : begin
          pc[11:0] <= {4'h0, immed};

          // Write PCSL + 1 to M(SP-1)
          bus_output_memory_addr <= sp_dec;
          memory_write_data <= pc_inc[3:0];
          memory_write_en <= 1;
        end
        {
          REG_CALLEND_SET_PCP, CYCLE_REG_FETCH
        } : begin
          pc[11:0] <= {np[3:0], immed};

          // Write PCSL + 1 to M(SP-1)
          bus_output_memory_addr <= sp_dec;
          memory_write_data <= pc_inc[3:0];
          memory_write_en <= 1;
        end
        {
          REG_JPBAEND, CYCLE_REG_FETCH
        } : begin
          pc[12:8] <= np;
          pc[3:0]  <= a;
        end
        default: begin
          // Do nothing
        end
      endcase

      if (bus_input_selector == REG_ALU_WITH_FLAGS && bus_output_selector != REG_FLAGS && current_cycle == CYCLE_REG_WRITE) begin
        // On write, using value from REG_ALU_WITH_FLAGS, set flags
        carry <= alu_carry;
        zero  <= alu_zero;
      end

      // PC increment
      if (increment_pc || (current_cycle == CYCLE_REG_FETCH && increment_selector == REG_PC)) begin
        pc[11:0] <= pc_inc;
      end

      // NP reset
      if (reset_np) begin
        np <= pc[12:8];
      end

      // Post-increment
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
  end
endmodule
