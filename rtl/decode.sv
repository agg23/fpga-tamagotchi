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
      12'h0XX: {microcode_start_addr, cycle_length} <= {0, CYCLE5};  // JP s
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

      12'hA0X: {microcode_start_addr, cycle_length} <= {10, CYCLE7};  // ADC XH, i
      12'hA1X: {microcode_start_addr, cycle_length} <= {11, CYCLE7};  // ADC XL, i
      12'hA2X: {microcode_start_addr, cycle_length} <= {12, CYCLE7};  // ADC YH, i
      12'hA3X: {microcode_start_addr, cycle_length} <= {13, CYCLE7};  // ADC YL, i

      12'hA4X: {microcode_start_addr, cycle_length} <= {14, CYCLE7};  // CP XH, i
      12'hA5X: {microcode_start_addr, cycle_length} <= {15, CYCLE7};  // CP XL, i
      12'hA6X: {microcode_start_addr, cycle_length} <= {16, CYCLE7};  // CP YH, i
      12'hA7X: {microcode_start_addr, cycle_length} <= {17, CYCLE7};  // CP YL, i

      12'hA8X: {microcode_start_addr, cycle_length} <= {18, CYCLE7};  // ADD r, q
      12'hA9X: {microcode_start_addr, cycle_length} <= {19, CYCLE7};  // ADC r, q
      12'hAAX: {microcode_start_addr, cycle_length} <= {20, CYCLE7};  // SUB r, q
      12'hABX: {microcode_start_addr, cycle_length} <= {21, CYCLE7};  // SBC r, q

      12'hACX: {microcode_start_addr, cycle_length} <= {22, CYCLE7};  // AND r, q
      12'hADX: {microcode_start_addr, cycle_length} <= {23, CYCLE7};  // OR r, q
      12'hAEX: {microcode_start_addr, cycle_length} <= {24, CYCLE7};  // XOR r, q
      12'hAFX: {microcode_start_addr, cycle_length} <= {25, CYCLE7};  // RLC r

      12'hBXX: {microcode_start_addr, cycle_length} <= {26, CYCLE5};  // LD X, e

      12'hCXX: begin
        case (opcode[7:6])
          2'b00: {microcode_start_addr, cycle_length} <= {27, CYCLE7};  // ADD r, i
          2'b01: {microcode_start_addr, cycle_length} <= {28, CYCLE7};  // ADC r, i
          2'b10: {microcode_start_addr, cycle_length} <= {29, CYCLE7};  // AND r, i
          2'b11: {microcode_start_addr, cycle_length} <= {30, CYCLE7};  // OR r, i
        endcase
      end
      12'hDXX: begin
        case (opcode[7:6])
          2'b00: {microcode_start_addr, cycle_length} <= {31, CYCLE7};  // XOR r, i
          2'b01: {microcode_start_addr, cycle_length} <= {32, CYCLE7};  // SBC r, i
          2'b10: {microcode_start_addr, cycle_length} <= {33, CYCLE7};  // FAN r, i
          2'b11: {microcode_start_addr, cycle_length} <= {34, CYCLE7};  // CP r, i
        endcase
      end
      12'hEXX: begin
        casex (opcode[7:0])
          8'b00XX_XXXX: {microcode_start_addr, cycle_length} <= {35, CYCLE5};  // LD r, i
          8'b010X_XXXX: {microcode_start_addr, cycle_length} <= {36, CYCLE5};  // PSET p
          8'b0110_XXXX: {microcode_start_addr, cycle_length} <= {37, CYCLE5};  // LDPX MX, i
          8'b0111_XXXX: {microcode_start_addr, cycle_length} <= {38, CYCLE5};  // LDPY MY, i

          8'b1000_00XX: {microcode_start_addr, cycle_length} <= {39, CYCLE5};  // LD XP, r
          8'b1000_01XX: {microcode_start_addr, cycle_length} <= {40, CYCLE5};  // LD XH, r
          8'b1000_10XX: {microcode_start_addr, cycle_length} <= {41, CYCLE5};  // LD XL, r
          8'b1000_11XX: {microcode_start_addr, cycle_length} <= {42, CYCLE5};  // RRC r

          8'b1001_00XX: {microcode_start_addr, cycle_length} <= {43, CYCLE5};  // LD YP, r
          8'b1001_01XX: {microcode_start_addr, cycle_length} <= {44, CYCLE5};  // LD YH, r
          8'b1001_10XX: {microcode_start_addr, cycle_length} <= {45, CYCLE5};  // LD YL, r
          // 8'b1001_11XX: {microcode_start_addr, cycle_length} <= {46, CYCLE5}; // Invalid opcode

          8'b1010_00XX: {microcode_start_addr, cycle_length} <= {46, CYCLE5};  // LD r, XP
          8'b1010_01XX: {microcode_start_addr, cycle_length} <= {47, CYCLE5};  // LD r, XH
          8'b1010_10XX: {microcode_start_addr, cycle_length} <= {48, CYCLE5};  // LD r, XL
          // 8'b1010_11XX: {microcode_start_addr, cycle_length} <= {49, CYCLE5}; // Invalid opcode

          8'b1011_00XX: {microcode_start_addr, cycle_length} <= {49, CYCLE5};  // LD r, YP
          8'b1011_01XX: {microcode_start_addr, cycle_length} <= {50, CYCLE5};  // LD r, YH
          8'b1011_10XX: {microcode_start_addr, cycle_length} <= {51, CYCLE5};  // LD r, YL
          // 8'b1011_11XX: {microcode_start_addr, cycle_length} <= {51, CYCLE5}; // Invalid opcode

          8'b1100_XXXX: {microcode_start_addr, cycle_length} <= {52, CYCLE5};  // LD r, q
          // 8'b1101_XXXX: {microcode_start_addr, cycle_length} <= {52, CYCLE5}; // Invalid opcode
          8'b1110_XXXX: {microcode_start_addr, cycle_length} <= {53, CYCLE5};  // LDPX r, q
          8'b1111_XXXX: {microcode_start_addr, cycle_length} <= {54, CYCLE5};  // LDPY r, q
        endcase
      end
      12'hF0X: {microcode_start_addr, cycle_length} <= {55, CYCLE7};  // CP r, q
      12'hF1X: {microcode_start_addr, cycle_length} <= {56, CYCLE7};  // FAN r, q
      12'hF2X: begin
        case (opcode[3:2])
          2'b10: {microcode_start_addr, cycle_length} <= {57, CYCLE7};  // ACPX MX, r
          2'b11: {microcode_start_addr, cycle_length} <= {58, CYCLE7};  // ACPY MY, r
        endcase
      end
      12'hF3X: begin
        case (opcode[3:2])
          2'b10: {microcode_start_addr, cycle_length} <= {59, CYCLE7};  // SCPX MX, r
          2'b11: {microcode_start_addr, cycle_length} <= {60, CYCLE7};  // SCPY MY, r
        endcase
      end
      12'hF4X: {microcode_start_addr, cycle_length} <= {61, CYCLE7};  // SET F, i
      12'hF5X: {microcode_start_addr, cycle_length} <= {62, CYCLE7};  // RST F, i

      12'hF6X: {microcode_start_addr, cycle_length} <= {63, CYCLE7};  // INC Mn
      12'hF7X: {microcode_start_addr, cycle_length} <= {64, CYCLE7};  // DEC Mn

      12'hF8X: {microcode_start_addr, cycle_length} <= {65, CYCLE5};  // LD Mn, A
      12'hF9X: {microcode_start_addr, cycle_length} <= {66, CYCLE5};  // LD Mn, B

      12'hFAX: {microcode_start_addr, cycle_length} <= {67, CYCLE5};  // LD A, Mn
      12'hFBX: {microcode_start_addr, cycle_length} <= {68, CYCLE5};  // LD B, Mn

      12'hFCX: begin
        case (opcode[3:0])
          4'b00XX: {microcode_start_addr, cycle_length} <= {69, CYCLE5};  // PUSH r
          4'b0100: {microcode_start_addr, cycle_length} <= {70, CYCLE5};  // PUSH XP
          4'b0101: {microcode_start_addr, cycle_length} <= {71, CYCLE5};  // PUSH XH
          4'b0110: {microcode_start_addr, cycle_length} <= {72, CYCLE5};  // PUSH XL
          4'b0111: {microcode_start_addr, cycle_length} <= {73, CYCLE5};  // PUSH YP
          4'b1000: {microcode_start_addr, cycle_length} <= {74, CYCLE5};  // PUSH YH
          4'b1001: {microcode_start_addr, cycle_length} <= {75, CYCLE5};  // PUSH YL
          4'b1010: {microcode_start_addr, cycle_length} <= {76, CYCLE5};  // PUSH F
          4'b1011: {microcode_start_addr, cycle_length} <= {77, CYCLE5};  // DEC SP
        endcase
      end

      12'hFDX: begin
        case (opcode[3:0])
          4'b00XX: {microcode_start_addr, cycle_length} <= {78, CYCLE5};  // POP r
          4'b0100: {microcode_start_addr, cycle_length} <= {79, CYCLE5};  // POP XP
          4'b0101: {microcode_start_addr, cycle_length} <= {80, CYCLE5};  // POP XH
          4'b0110: {microcode_start_addr, cycle_length} <= {81, CYCLE5};  // POP XL
          4'b0111: {microcode_start_addr, cycle_length} <= {82, CYCLE5};  // POP YP
          4'b1000: {microcode_start_addr, cycle_length} <= {83, CYCLE5};  // POP YH
          4'b1001: {microcode_start_addr, cycle_length} <= {84, CYCLE5};  // POP YL
          4'b1010: {microcode_start_addr, cycle_length} <= {85, CYCLE5};  // POP F
          4'b1011: {microcode_start_addr, cycle_length} <= {86, CYCLE5};  // INC SP

          4'b1110: {microcode_start_addr, cycle_length} <= {87, CYCLE12};  // RETS
          4'b1111: begin  // RET
            {microcode_start_addr, cycle_length} <= {88, CYCLE7};

            skip_pc_increment <= 1;
          end
        endcase
      end

      12'hFEX: begin
        case (opcode[3:0])
          4'b00XX: {microcode_start_addr, cycle_length} <= {89, CYCLE5};  // LD SPH, r
          4'b01XX: {microcode_start_addr, cycle_length} <= {90, CYCLE5};  // LD r, SPH

          4'b1000: {microcode_start_addr, cycle_length} <= {91, CYCLE5};  // JPBA
        endcase
      end

      12'hFFX: begin
        case (opcode[3:0])
          4'b00XX: {microcode_start_addr, cycle_length} <= {91, CYCLE5};  // LD SPL, r
          4'b01XX: {microcode_start_addr, cycle_length} <= {92, CYCLE5};  // LD r, SPL

          4'b1000: {microcode_start_addr, cycle_length} <= {93, CYCLE5};  // HALT
          4'b1001: {microcode_start_addr, cycle_length} <= {94, CYCLE5};  // SLP
          4'b1011: {microcode_start_addr, cycle_length} <= {95, CYCLE5};  // NOP5
          4'b1111: {microcode_start_addr, cycle_length} <= {96, CYCLE7};  // NOP7
        endcase
      end
    endcase
  end

endmodule
