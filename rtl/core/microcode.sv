import types::*;

module microcode (
    input wire clk,
    input wire clk_en,
    input wire clk_2x_en,

    input wire reset,

    // Reg
    input wire zero,
    input wire carry,
    input wire interrupt,
    input wire [7:0] immed,

    // Control
    output wire increment_pc,
    output wire reset_np,

    input wire disable_interrupt,
    input wire [6:0] microcode_start_addr,
    input instr_length cycle_length,

    // Interrupt
    input wire [14:0] interrupt_req,
    output reg performing_interrupt = 0,
    output reg [3:0] interrupt_address,

    // Bus
    output microcode_cycle current_cycle,
    output wire is_last_cycle_step,

    output reg_type bus_input_selector,
    output reg_type bus_output_selector,
    output reg_inc_type increment_selector,
    output alu_op alu_operation,

    // Hack for RET
    output wire override_memory_read_en,

    // Indicates ready for savestate halt
    output wire ss_ready
);
  typedef enum bit [3:0] {
    DECODE,   // Single cycle
    STEP1,
    STEP1_2,
    STEP2,
    STEP2_2,
    STEP3,
    STEP3_2,
    STEP4,    // Single cycle
    STEP5,
    STEP5_2,
    STEP6,
    STEP6_2
  } microcode_stage;

  reg [15:0] rom[512];

  // TODO: ModelSim only
  // initial $readmemh("../../core/rom/microcode.hex", rom);
  initial $readmemh("C:/Users/adam/code/fpga/tamagotchi/rtl/core/rom/microcode.hex", rom);

  microcode_stage stage = STEP6_2;

  reg [15:0] instruction_big_endian = 0;
  reg [8:0] micro_pc = 0;

  wire [15:0] instruction = {instruction_big_endian[7:0], instruction_big_endian[15:8]};

  reg halt = 0;

  // Interrupts
  reg queued_interrupt = 0;

  wire is_interrupt_requested = interrupt && |interrupt_req && ~performing_interrupt && ~disable_interrupt;
  // Halt must go through the queue
  wire should_begin_interrupt = queued_interrupt || (is_interrupt_requested && ~halt);

  instr_length actual_cycle_length;
  // Interrupt technically uses a 7 and a 5 cycle instruction, but for ease we collapse this into one 12
  assign actual_cycle_length = performing_interrupt ? CYCLE12 : cycle_length;

  assign is_last_cycle_step = stage + 1 == cycle_count_int(actual_cycle_length) || stage == STEP6_2;
  wire is_last_fetch_step = stage + 2 == cycle_count_int(actual_cycle_length);

  // This is a dirty hack to provide memory data to the bus for the RET instruction
  reg_type temp_override_bus_input_selector;
  reg disable_increment = 0;
  reg prevent_reset_np = 0;
  assign increment_pc = ~disable_increment && is_last_fetch_step;
  assign reset_np = ~prevent_reset_np && is_last_cycle_step;

  assign override_memory_read_en = temp_override_bus_input_selector != REG_ALU && current_cycle == CYCLE_REG_WRITE;

  assign ss_ready = stage == DECODE && ~should_begin_interrupt && ~disable_interrupt;

  int interrupt_req_i;

  always @(posedge clk) begin
    if (reset) begin
      stage <= STEP6_2;

      queued_interrupt <= 0;
      performing_interrupt <= 0;
    end else if (clk_en) begin
      if (is_interrupt_requested) begin
        // Interrupt flag set and an interrupt requested
        queued_interrupt <= 1;
      end

      if (is_last_cycle_step || stage == STEP6_2) begin
        // Finished cycle, go back to decode
        stage <= DECODE;
        performing_interrupt <= 0;

        if (should_begin_interrupt) begin
          // If incoming interrupt on the same cycle as enter decode, short circuit and start processing immediately
          performing_interrupt <= 1;
          queued_interrupt <= 0;

          interrupt_req_i = 14;
          while (interrupt_req_i > 0 && ~interrupt_req[interrupt_req_i]) begin
            interrupt_req_i = interrupt_req_i - 1;
          end

          interrupt_address <= interrupt_req_i[3:0];
        end
      end else begin
        stage <= microcode_stage'(stage + 1);
      end

      if (halt && ~should_begin_interrupt) begin
        stage <= STEP6_2;
      end
    end
  end

  function reg_type final_selector(reg_type selector);
    if (selector == REG_IMM_ADDR_L || selector == REG_IMM_ADDR_H || selector == REG_IMM_ADDR_P) begin
      final_selector = imm_addressed_reg(selector, immed[5:0]);
    end else begin
      final_selector = selector;
    end
  endfunction

  task assign_bus_selectors(reg [4:0] in, reg [4:0] out);
    reg_type temp_input;
    reg_type temp_output;

    temp_input  = reg_type'(in);
    temp_output = reg_type'(out);

    bus_input_selector  <= final_selector(temp_input);
    bus_output_selector <= final_selector(temp_output);
  endtask

  reg microcode_tick = 0;
  microcode_stage prev_stage = STEP6_2;

  // Comb
  reg cycle_second_step;

  always @(posedge clk) begin
    reg [8:0] microcode_addr;

    if (reset) begin
      prev_stage <= STEP6_2;

      microcode_tick <= 0;
      micro_pc <= 0;
      instruction_big_endian <= 0;

      bus_input_selector <= REG_ALU;
      bus_output_selector <= REG_ALU;
      increment_selector <= REG_NONE;
      temp_override_bus_input_selector <= REG_ALU;

      halt <= 0;
      disable_increment <= 0;
      prevent_reset_np <= 0;
    end else if (clk_2x_en) begin
      prev_stage <= stage;

      if (performing_interrupt) begin
        // End halt if we were halted
        halt <= 0;
      end

      if (stage != prev_stage) begin
        microcode_tick <= 0;
      end else begin
        microcode_tick <= 1;
      end

      microcode_addr = micro_pc;

      if (current_cycle == CYCLE_REG_FETCH && ~microcode_tick && temp_override_bus_input_selector != REG_ALU) begin
        // Hack for RET (RETEND microcode)
        bus_input_selector <= temp_override_bus_input_selector;
      end

      if (stage == DECODE && microcode_tick) begin
        if (performing_interrupt) begin
          // Interrupt instruction is at #100
          microcode_addr = {7'd100, 2'b00};
        end else begin
          microcode_addr = {microcode_start_addr, 2'b00};
        end

        micro_pc <= microcode_addr;
        disable_increment <= 0;
        prevent_reset_np <= 0;
      end else if (cycle_second_step && ~is_last_cycle_step && ~microcode_tick) begin
        // Execute microcode instruction
        // Defaults
        alu_operation <= ALU_ADD;
        bus_input_selector <= REG_ALU;
        bus_output_selector <= REG_ALU;
        increment_selector <= REG_NONE;

        temp_override_bus_input_selector <= REG_ALU;

        micro_pc <= micro_pc + 9'h1;

        casex (instruction[15:13])
          3'b000: begin
            // NOP
          end
          3'b001: begin
            // TRANSFER
            assign_bus_selectors(instruction[12:8], instruction[7:3]);
            increment_selector <= reg_inc_type'(instruction[2:0]);

            if (reg_type'(instruction[7:3]) == REG_NPP) begin
              // If NPP was modified in this instruction, don't reset NP
              prevent_reset_np <= 1;
            end
          end
          3'b010: begin
            // TRANSALU
            alu_operation <= alu_op'(instruction[11:8]);
            assign_bus_selectors(0, instruction[7:3]);
            // Override assign_bus_selectors for input
            bus_input_selector <= REG_ALU_WITH_FLAGS;
            increment_selector <= reg_inc_type'(instruction[2:0]);
          end
          3'b011: begin
            if (instruction[12]) begin
              // STARTINTERRUPT
              bus_input_selector  <= REG_PCP;
              bus_output_selector <= REG_STARTINTERRUPT;
              increment_selector  <= REG_SP_DEC;
            end else begin
              // SETPC
              bus_output_selector <= REG_SETPC;
              disable_increment   <= 1;
            end
          end
          3'b100: begin
            // JMP
            reg flag_nzero_carry;
            reg flag_set;

            flag_nzero_carry = instruction[11];
            flag_set = instruction[10];

            if (instruction[12]) begin
              // Conditional
              if ((~flag_nzero_carry && (flag_set == zero)) || (flag_nzero_carry && (flag_set == carry))) begin
                // Condition met
                microcode_addr = instruction[8:0];
              end else begin
                // Condition not met, move to next instr
                microcode_addr = microcode_addr + 9'h1;
              end
            end else begin
              // Always jump
              microcode_addr = instruction[8:0];
            end

            // JMP and immediately load new microcode address as well
            micro_pc <= microcode_addr;
          end
          3'b101: begin
            casex (instruction[12:11])
              2'b00: begin
                // CALLEND
                if (instruction[0]) begin
                  // Copy NPP to PCP
                  bus_output_selector <= REG_CALLEND_SET_PCP;
                end else begin
                  // Zero PCP
                  bus_output_selector <= REG_CALLEND_ZERO_PCP;
                end

                increment_selector <= REG_SP_DEC;
              end
              2'b01: begin
                // CALLSTART
                bus_output_selector <= REG_MSP_DEC;
                increment_selector  <= REG_SP_DEC;

                if (instruction[0]) begin
                  // PCP copy
                  bus_input_selector <= REG_PCP_INC;
                end else begin
                  // PCSH copy
                  bus_input_selector <= REG_PCSH_INC;
                end
              end
              2'b10: begin
                // RETEND
                bus_input_selector <= REG_MSP;
                increment_selector <= REG_SP_INC;

                if (instruction[0]) begin
                  // PCP copy
                  bus_output_selector <= REG_PCP_EARLY;
                end else begin
                  // PCSH copy
                  bus_output_selector <= REG_PCSH;

                  temp_override_bus_input_selector <= REG_MSP_INC;
                end
              end
            endcase
          end
          3'b110: begin
            // JPBAEND
            bus_output_selector <= REG_JPBAEND;
          end
          3'b111: begin
            // HALT
            // TODO: Do we need to do anything with the oscillator?
            halt <= 1;

            increment_selector <= REG_PC;
          end
        endcase
      end

      // Switch from big endian to little
      instruction_big_endian <= rom[microcode_addr];
    end
  end

  always_comb begin
    // Set cycle
    cycle_second_step = 0;

    case (stage)
      DECODE: begin
        current_cycle = CYCLE_NONE;
        cycle_second_step = 1;
      end
      STEP1, STEP2, STEP3, STEP5, STEP6: current_cycle = CYCLE_REG_FETCH;

      STEP1_2, STEP2_2, STEP3_2, STEP4, STEP5_2, STEP6_2: begin
        current_cycle = CYCLE_REG_WRITE;
        cycle_second_step = 1;
      end
    endcase
  end
endmodule
