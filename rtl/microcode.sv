import types::*;

module microcode (
    input wire clk,
    input wire clk_2x,

    input wire reset_n,

    // Reg
    input wire zero,
    input wire carry,

    // Control
    output wire increment_pc,
    output wire reset_np,

    input wire [6:0] microcode_start_addr,
    input instr_length cycle_length,

    // Bus
    output microcode_cycle current_cycle,

    output reg_type bus_input_selector,
    output reg_type bus_output_selector,
    output reg_inc_type increment_selector,
    output alu_op alu_operation
);
  typedef enum {
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

  (* ram_init_file = "rom/microcode.mif" *)
  reg [15:0] rom[1024];

  // TODO: ModelSim only
  initial $readmemh("C:/Users/adam/code/fpga/tamagotchi/rtl/rom/microcode.hex", rom);

  microcode_stage stage = STEP6_2;

  reg [15:0] instruction_big_endian = 0;
  reg [9:0] micro_pc = 0;

  wire [15:0] instruction = {instruction_big_endian[7:0], instruction_big_endian[15:8]};

  reg init_instruction = 1;
  reg completed_init = 0;

  instr_length actual_cycle_length;
  assign actual_cycle_length = init_instruction ? CYCLE5 : cycle_length;

  wire last_cycle_step = stage + 1 == cycle_count_int(actual_cycle_length);
  wire last_fetch_step = stage + 2 == cycle_count_int(actual_cycle_length);

  // This is a dirty hack to provide memory data to the bus for the RET instruction
  reg_type temp_override_bus_input_selector;
  reg halt = 0;
  reg disable_increment = 0;
  reg prevent_reset_np = 0;
  assign increment_pc = ~disable_increment && last_fetch_step;
  assign reset_np = ~prevent_reset_np && last_cycle_step;

  always @(posedge clk) begin
    if (~reset_n || halt) begin
      stage <= STEP6_2;
    end else begin
      if (last_cycle_step || stage == STEP6_2) begin
        // Finished cycle, go back to decode
        stage <= DECODE;

        if (~completed_init) begin
          completed_init <= 1;
        end else begin
          init_instruction <= 0;
        end
      end else begin
        $cast(stage, stage + 1);
      end
    end
  end

  reg microcode_tick = 0;
  microcode_stage prev_stage = STEP6_2;
  reg cycle_second_step;

  always @(posedge clk_2x) begin
    reg [9:0] microcode_addr;
    reg_type temp_source;
    reg_type temp_dest;
    reg_inc_type temp_inc;
    alu_op temp_op;

    if (~reset_n) begin
      microcode_tick <= 0;
      micro_pc <= 0;

      bus_input_selector <= REG_ALU;
      bus_output_selector <= REG_ALU;
      increment_selector <= REG_NONE;

      halt <= 0;
      disable_increment <= 0;
      prevent_reset_np <= 0;

      init_instruction <= 1;
      completed_init <= 0;
    end else begin
      prev_stage <= stage;

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
        if (init_instruction) begin
          // Init instruction is at #100
          microcode_addr = {7'd100, 2'b00};
        end else begin
          microcode_addr = {microcode_start_addr, 2'b00};
        end

        micro_pc <= microcode_addr;
        disable_increment <= 0;
        prevent_reset_np <= 0;
      end else if (cycle_second_step && ~last_cycle_step && ~microcode_tick) begin
        // Execute microcode instruction
        // Defaults
        alu_operation <= ALU_ADD;
        bus_input_selector <= REG_ALU;
        bus_output_selector <= REG_ALU;
        increment_selector <= REG_NONE;

        temp_override_bus_input_selector <= REG_ALU;

        micro_pc <= micro_pc + 1;

        casex (instruction[15:13])
          3'b000: begin
            // NOP
          end
          3'b001: begin
            // TRANSFER
            $cast(temp_source, instruction[12:8]);
            $cast(temp_dest, instruction[7:3]);
            $cast(temp_inc, instruction[2:0]);

            bus_input_selector  <= temp_source;
            bus_output_selector <= temp_dest;
            increment_selector  <= temp_inc;

            if (temp_dest == REG_NPP) begin
              // If NPP was modified in this instruction, don't reset NP
              prevent_reset_np <= 1;
            end
          end
          3'b010: begin
            // TRANSALU
            $cast(temp_op, instruction[11:8]);
            $cast(temp_dest, instruction[7:3]);
            $cast(temp_inc, instruction[2:0]);

            alu_operation <= temp_op;
            bus_input_selector <= REG_ALU_WITH_FLAGS;
            bus_output_selector <= temp_dest;
            increment_selector <= temp_inc;
          end
          3'b011: begin
            disable_increment <= 1;

            if (instruction[12]) begin
              // SETPCVEC
              bus_output_selector <= REG_SETPCVEC;
            end else begin
              // SETPC
              bus_output_selector <= REG_SETPC;
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
                microcode_addr = instruction[9:0];
              end else begin
                // Condition not met, move to next instr
                microcode_addr = microcode_addr + 1;
              end
            end else begin
              // Always jump
              microcode_addr = instruction[9:0];
            end

            // JMP and immediately load new microcode address as well
            micro_pc <= microcode_addr;
          end
          3'b101: begin
            if (instruction[12]) begin
              // RETEND
              if (instruction[0]) begin
                // PCP copy
                bus_input_selector  <= REG_MSP;
                bus_output_selector <= REG_PCP_EARLY;
                increment_selector  <= REG_SP_INC;
              end else begin
                // PCSH copy
                bus_input_selector <= REG_MSP;
                bus_output_selector <= REG_PCSH;
                increment_selector <= REG_SP_INC;

                temp_override_bus_input_selector <= REG_MSP_INC;
              end
            end else begin
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
          end
          3'b110: begin
            // JPBAEND
            bus_output_selector <= REG_JPBAEND;
          end
          3'b111: begin
            // HALT
            // TODO: Do we need to do anything with the oscillator?
            halt <= 1;
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
