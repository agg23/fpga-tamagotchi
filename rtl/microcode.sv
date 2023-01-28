import types::*;

module microcode (
    input wire clk,

    // Control
    input wire skip_pc_increment,

    input wire [6:0] microcode_start_addr,
    input instr_length cycle_length,

    // Bus
    output microcode_cycle current_cycle,

    output reg_type bus_input_selector,
    output reg_type bus_output_selector,
    output reg_inc_type increment_selector
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

  microcode_stage stage = DECODE;

  reg [15:0] instruction = 0;
  reg [9:0] micro_pc = 0;

  always @(posedge clk) begin
    reg [9:0] microcode_addr;
    reg_type temp_source;
    reg_type temp_dest;
    reg_inc_type temp_inc;

    if (stage + 1 == cycle_count_int(cycle_length)) begin
      // Finished cycle, go back to decode
      stage <= DECODE;
    end else begin
      $cast(stage, stage + 1);
    end

    // Defaults
    bus_input_selector  <= REG_ALU;
    bus_output_selector <= REG_ALU;
    increment_selector  <= REG_NONE;

    if (stage == DECODE) begin
      microcode_addr = {microcode_start_addr, 2'b00};
    end else begin
      // Execute microcode instruction
      microcode_addr = micro_pc;

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
        end
        // TODO
      endcase
    end

    instruction <= rom[microcode_addr];
    micro_pc <= microcode_addr + 1;
  end

  always_comb begin
    // Set cycle
    case (stage)
      DECODE: current_cycle = CYCLE_NONE;
      STEP1:  current_cycle = CYCLE_REG_FETCH;
      STEP2:  current_cycle = CYCLE_REG_FETCH;
      STEP3:  current_cycle = CYCLE_REG_FETCH;
      STEP5:  current_cycle = CYCLE_REG_FETCH;
      STEP6:  current_cycle = CYCLE_REG_FETCH;

      STEP1_2: current_cycle = CYCLE_REG_WRITE;
      STEP2_2: current_cycle = CYCLE_REG_WRITE;
      STEP3_2: current_cycle = CYCLE_REG_WRITE;
      STEP4:   current_cycle = CYCLE_REG_WRITE;
      STEP5_2: current_cycle = CYCLE_REG_WRITE;
      STEP6_2: current_cycle = CYCLE_REG_WRITE;
    endcase
  end
endmodule
