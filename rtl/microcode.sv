import types::*;

module microcode (
    input wire clk,
    input wire clk_2x,

    input wire reset_n,

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
  // reg [15:0] rom[1024];
  reg [15:0] rom[3] = '{16'h2338, 16'h2340, 16'h2729};

  microcode_stage stage = STEP6_2;

  reg [15:0] instruction = 0;
  reg [9:0] micro_pc = 0;

  wire last_cycle_step = stage + 1 == cycle_count_int(cycle_length);

  always @(posedge clk) begin
    if (~reset_n) begin
      stage <= STEP6_2;
    end else begin
      if (last_cycle_step || stage == STEP6_2) begin
        // Finished cycle, go back to decode
        stage <= DECODE;
      end else begin
        $cast(stage, stage + 1);
      end
    end
  end

  reg microcode_tick = 0;
  microcode_stage prev_stage;
  reg cycle_second_step;

  always @(posedge clk_2x) begin
    reg [9:0] microcode_addr;
    reg_type temp_source;
    reg_type temp_dest;
    reg_inc_type temp_inc;

    if (~reset_n) begin
      microcode_tick <= 0;
      micro_pc <= 0;

      bus_input_selector <= REG_ALU;
      bus_output_selector <= REG_ALU;
      increment_selector <= REG_NONE;
    end else begin
      prev_stage <= stage;

      if (stage != prev_stage && stage != STEP4) begin
        microcode_tick <= 0;
      end else begin
        microcode_tick <= 1;
      end

      microcode_addr = micro_pc;

      if (stage == DECODE && microcode_tick) begin
        microcode_addr = {microcode_start_addr, 2'b00};

        micro_pc <= microcode_addr;
      end else if (cycle_second_step && ~last_cycle_step && ~microcode_tick) begin
        // Execute microcode instruction
        // Defaults
        bus_input_selector  <= REG_ALU;
        bus_output_selector <= REG_ALU;
        increment_selector  <= REG_NONE;

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

        micro_pc <= micro_pc + 1;
      end

      instruction <= rom[microcode_addr];
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
