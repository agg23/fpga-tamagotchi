import types::*;

module decode (
    // input wire clk,

    input wire [11:0] opcode,

    output reg skip_pc_increment,

    output reg [6:0] microcode_start_addr,
    output instr_length cycle_length,

    output wire [7:0] immed
);
  // Arguments
  wire [7:0] immediate = opcode[7:0];

  reg [1:0] r = 0;
  reg [1:0] q = 0;

  assign immed = opcode[7:0];

  always_comb begin
    skip_pc_increment <= 0;
    microcode_start_addr <= 0;

    casex (opcode)
      // TODO: Restore CYCLE5
      // 12'h0XX: {microcode_start_addr, cycle_length} <= {0, CYCLE5};  // JP s
      12'h0XX: {microcode_start_addr, cycle_length} <= {0, CYCLE7};  // Testing
      12'h1XX: begin  // RETD e
        {microcode_start_addr, cycle_length} <= {1, CYCLE12};

        skip_pc_increment <= 1;
      end
      12'h2XX: {microcode_start_addr, cycle_length} <= {2, CYCLE5};  // JP C, s
      12'h3XX: {microcode_start_addr, cycle_length} <= {3, CYCLE5};  // JP NC, s
      12'h4XX: begin  // CALL s
        {microcode_start_addr, cycle_length} <= {4, CYCLE7};

        skip_pc_increment <= 1;
      end
      12'h5XX: begin  // CALZ s
        {microcode_start_addr, cycle_length} <= {5, CYCLE7};

        skip_pc_increment <= 1;
      end
      12'h6XX: {microcode_start_addr, cycle_length} <= {6, CYCLE5};  // JP Z, s
      12'h7XX: {microcode_start_addr, cycle_length} <= {7, CYCLE5};  // JP NZ, s
      12'h8XX: {microcode_start_addr, cycle_length} <= {8, CYCLE5};  // LD Y, e
      12'h9XX: {microcode_start_addr, cycle_length} <= {9, CYCLE5};  // LBPX MX, e
      // TODO
    endcase
  end

endmodule
