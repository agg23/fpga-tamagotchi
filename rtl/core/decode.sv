import types::*;

module decode (
    input wire clk,
    input wire clk_2x_en,

    input wire [11:0] opcode,

    output reg skip_pc_increment = 0,

    output reg [6:0] microcode_start_addr = 0,
    output instr_length cycle_length = CYCLE5,
    output reg disable_interrupt = 0,

    output reg [7:0] immed = 0
);
  always @(posedge clk) begin
    if (clk_2x_en) begin
      skip_pc_increment <= 0;
      microcode_start_addr <= 0;
      cycle_length <= CYCLE5;
      disable_interrupt <= 0;
      immed <= opcode[7:0];

      casex (opcode)
        12'h0XX: {microcode_start_addr, cycle_length} <= {7'd0, CYCLE5};  // JP s
        12'h1XX: begin  // RETD e
          {microcode_start_addr, cycle_length} <= {7'd1, CYCLE12};

          skip_pc_increment <= 1;
        end
        12'h2XX: {microcode_start_addr, cycle_length} <= {7'd2, CYCLE5};  // JP C, s
        12'h3XX: {microcode_start_addr, cycle_length} <= {7'd3, CYCLE5};  // JP NC, s
        12'h4XX: begin  // CALL s
          {microcode_start_addr, cycle_length} <= {7'd4, CYCLE7};

          skip_pc_increment <= 1;
        end
        12'h5XX: begin  // CALZ s
          {microcode_start_addr, cycle_length} <= {7'd5, CYCLE7};

          skip_pc_increment <= 1;
        end
        12'h6XX: {microcode_start_addr, cycle_length} <= {7'd6, CYCLE5};  // JP Z, s
        12'h7XX: {microcode_start_addr, cycle_length} <= {7'd7, CYCLE5};  // JP NZ, s
        12'h8XX: {microcode_start_addr, cycle_length} <= {7'd8, CYCLE5};  // LD Y, e
        12'h9XX: {microcode_start_addr, cycle_length} <= {7'd9, CYCLE5};  // LBPX MX, e

        12'hA0X: {microcode_start_addr, cycle_length} <= {7'd10, CYCLE7};  // ADC XH, i
        12'hA1X: {microcode_start_addr, cycle_length} <= {7'd11, CYCLE7};  // ADC XL, i
        12'hA2X: {microcode_start_addr, cycle_length} <= {7'd12, CYCLE7};  // ADC YH, i
        12'hA3X: {microcode_start_addr, cycle_length} <= {7'd13, CYCLE7};  // ADC YL, i

        12'hA4X: {microcode_start_addr, cycle_length} <= {7'd14, CYCLE7};  // CP XH, i
        12'hA5X: {microcode_start_addr, cycle_length} <= {7'd15, CYCLE7};  // CP XL, i
        12'hA6X: {microcode_start_addr, cycle_length} <= {7'd16, CYCLE7};  // CP YH, i
        12'hA7X: {microcode_start_addr, cycle_length} <= {7'd17, CYCLE7};  // CP YL, i

        12'hA8X: {microcode_start_addr, cycle_length} <= {7'd18, CYCLE7};  // ADD r, q
        12'hA9X: {microcode_start_addr, cycle_length} <= {7'd19, CYCLE7};  // ADC r, q
        12'hAAX: {microcode_start_addr, cycle_length} <= {7'd20, CYCLE7};  // SUB r, q
        12'hABX: {microcode_start_addr, cycle_length} <= {7'd21, CYCLE7};  // SBC r, q

        12'hACX: {microcode_start_addr, cycle_length} <= {7'd22, CYCLE7};  // AND r, q
        12'hADX: {microcode_start_addr, cycle_length} <= {7'd23, CYCLE7};  // OR r, q
        12'hAEX: {microcode_start_addr, cycle_length} <= {7'd24, CYCLE7};  // XOR r, q
        12'hAFX: {microcode_start_addr, cycle_length} <= {7'd25, CYCLE7};  // RLC r

        12'hBXX: {microcode_start_addr, cycle_length} <= {7'd26, CYCLE5};  // LD X, e

        12'hCXX: begin
          casex (opcode[7:6])
            2'b00: {microcode_start_addr, cycle_length} <= {7'd27, CYCLE7};  // ADD r, i
            2'b01: {microcode_start_addr, cycle_length} <= {7'd28, CYCLE7};  // ADC r, i
            2'b10: {microcode_start_addr, cycle_length} <= {7'd29, CYCLE7};  // AND r, i
            2'b11: {microcode_start_addr, cycle_length} <= {7'd30, CYCLE7};  // OR r, i
          endcase
        end
        12'hDXX: begin
          casex (opcode[7:6])
            2'b00: {microcode_start_addr, cycle_length} <= {7'd31, CYCLE7};  // XOR r, i
            2'b01: {microcode_start_addr, cycle_length} <= {7'd32, CYCLE7};  // SBC r, i
            2'b10: {microcode_start_addr, cycle_length} <= {7'd33, CYCLE7};  // FAN r, i
            2'b11: {microcode_start_addr, cycle_length} <= {7'd34, CYCLE7};  // CP r, i
          endcase
        end
        12'hEXX: begin
          casex (opcode[7:0])
            8'b00XX_XXXX: {microcode_start_addr, cycle_length} <= {7'd35, CYCLE5};  // LD r, i
            8'b010X_XXXX: begin  // PSET p
              {microcode_start_addr, cycle_length} <= {7'd36, CYCLE5};

              disable_interrupt <= 1;
            end
            8'b0110_XXXX: {microcode_start_addr, cycle_length} <= {7'd37, CYCLE5};  // LDPX MX, i
            8'b0111_XXXX: {microcode_start_addr, cycle_length} <= {7'd38, CYCLE5};  // LDPY MY, i

            8'b1000_00XX: {microcode_start_addr, cycle_length} <= {7'd39, CYCLE5};  // LD XP, r
            8'b1000_01XX: {microcode_start_addr, cycle_length} <= {7'd40, CYCLE5};  // LD XH, r
            8'b1000_10XX: {microcode_start_addr, cycle_length} <= {7'd41, CYCLE5};  // LD XL, r
            8'b1000_11XX: {microcode_start_addr, cycle_length} <= {7'd42, CYCLE5};  // RRC r

            8'b1001_00XX: {microcode_start_addr, cycle_length} <= {7'd43, CYCLE5};  // LD YP, r
            8'b1001_01XX: {microcode_start_addr, cycle_length} <= {7'd44, CYCLE5};  // LD YH, r
            8'b1001_10XX: {microcode_start_addr, cycle_length} <= {7'd45, CYCLE5};  // LD YL, r
            // 8'b1001_11XX: {microcode_start_addr, cycle_length} <= {46, CYCLE5}; // Invalid opcode

            8'b1010_00XX: {microcode_start_addr, cycle_length} <= {7'd46, CYCLE5};  // LD r, XP
            8'b1010_01XX: {microcode_start_addr, cycle_length} <= {7'd47, CYCLE5};  // LD r, XH
            8'b1010_10XX: {microcode_start_addr, cycle_length} <= {7'd48, CYCLE5};  // LD r, XL
            // 8'b1010_11XX: {microcode_start_addr, cycle_length} <= {49, CYCLE5}; // Invalid opcode

            8'b1011_00XX: {microcode_start_addr, cycle_length} <= {7'd49, CYCLE5};  // LD r, YP
            8'b1011_01XX: {microcode_start_addr, cycle_length} <= {7'd50, CYCLE5};  // LD r, YH
            8'b1011_10XX: {microcode_start_addr, cycle_length} <= {7'd51, CYCLE5};  // LD r, YL
            // 8'b1011_11XX: {microcode_start_addr, cycle_length} <= {51, CYCLE5}; // Invalid opcode

            8'b1100_XXXX: {microcode_start_addr, cycle_length} <= {7'd52, CYCLE5};  // LD r, q
            // 8'b1101_XXXX: {microcode_start_addr, cycle_length} <= {52, CYCLE5}; // Invalid opcode
            8'b1110_XXXX: {microcode_start_addr, cycle_length} <= {7'd53, CYCLE5};  // LDPX r, q
            8'b1111_XXXX: {microcode_start_addr, cycle_length} <= {7'd54, CYCLE5};  // LDPY r, q
            default: begin
              // Do nothing
            end
          endcase
        end
        12'hF0X: {microcode_start_addr, cycle_length} <= {7'd55, CYCLE7};  // CP r, q
        12'hF1X: {microcode_start_addr, cycle_length} <= {7'd56, CYCLE7};  // FAN r, q
        12'hF2X: begin
          casex (opcode[3:2])
            2'b10: {microcode_start_addr, cycle_length} <= {7'd57, CYCLE7};  // ACPX MX, r
            2'b11: {microcode_start_addr, cycle_length} <= {7'd58, CYCLE7};  // ACPY MY, r
            default: begin
              // Do nothing
            end
          endcase
        end
        12'hF3X: begin
          casex (opcode[3:2])
            2'b10: {microcode_start_addr, cycle_length} <= {7'd59, CYCLE7};  // SCPX MX, r
            2'b11: {microcode_start_addr, cycle_length} <= {7'd60, CYCLE7};  // SCPY MY, r
            default: begin
              // Do nothing
            end
          endcase
        end
        12'hF4X: {microcode_start_addr, cycle_length} <= {7'd61, CYCLE7};  // SET F, i
        12'hF5X: {microcode_start_addr, cycle_length} <= {7'd62, CYCLE7};  // RST F, i

        12'hF6X: {microcode_start_addr, cycle_length} <= {7'd63, CYCLE7};  // INC Mn
        12'hF7X: {microcode_start_addr, cycle_length} <= {7'd64, CYCLE7};  // DEC Mn

        12'hF8X: {microcode_start_addr, cycle_length} <= {7'd65, CYCLE5};  // LD Mn, A
        12'hF9X: {microcode_start_addr, cycle_length} <= {7'd66, CYCLE5};  // LD Mn, B

        12'hFAX: {microcode_start_addr, cycle_length} <= {7'd67, CYCLE5};  // LD A, Mn
        12'hFBX: {microcode_start_addr, cycle_length} <= {7'd68, CYCLE5};  // LD B, Mn

        12'hFCX: begin
          casex (opcode[3:0])
            4'b00XX: {microcode_start_addr, cycle_length} <= {7'd69, CYCLE5};  // PUSH r
            4'b0100: {microcode_start_addr, cycle_length} <= {7'd70, CYCLE5};  // PUSH XP
            4'b0101: {microcode_start_addr, cycle_length} <= {7'd71, CYCLE5};  // PUSH XH
            4'b0110: {microcode_start_addr, cycle_length} <= {7'd72, CYCLE5};  // PUSH XL
            4'b0111: {microcode_start_addr, cycle_length} <= {7'd73, CYCLE5};  // PUSH YP
            4'b1000: {microcode_start_addr, cycle_length} <= {7'd74, CYCLE5};  // PUSH YH
            4'b1001: {microcode_start_addr, cycle_length} <= {7'd75, CYCLE5};  // PUSH YL
            4'b1010: {microcode_start_addr, cycle_length} <= {7'd76, CYCLE5};  // PUSH F
            4'b1011: {microcode_start_addr, cycle_length} <= {7'd77, CYCLE5};  // DEC SP
            default: begin
              // Do nothing
            end
          endcase
        end

        12'hFDX: begin
          casex (opcode[3:0])
            4'b00XX: {microcode_start_addr, cycle_length} <= {7'd78, CYCLE5};  // POP r
            4'b0100: {microcode_start_addr, cycle_length} <= {7'd79, CYCLE5};  // POP XP
            4'b0101: {microcode_start_addr, cycle_length} <= {7'd80, CYCLE5};  // POP XH
            4'b0110: {microcode_start_addr, cycle_length} <= {7'd81, CYCLE5};  // POP XL
            4'b0111: {microcode_start_addr, cycle_length} <= {7'd82, CYCLE5};  // POP YP
            4'b1000: {microcode_start_addr, cycle_length} <= {7'd83, CYCLE5};  // POP YH
            4'b1001: {microcode_start_addr, cycle_length} <= {7'd84, CYCLE5};  // POP YL
            4'b1010: {microcode_start_addr, cycle_length} <= {7'd85, CYCLE5};  // POP F
            4'b1011: {microcode_start_addr, cycle_length} <= {7'd86, CYCLE5};  // INC SP

            4'b1110: {microcode_start_addr, cycle_length} <= {7'd87, CYCLE12};  // RETS
            4'b1111: begin  // RET
              {microcode_start_addr, cycle_length} <= {7'd88, CYCLE7};

              skip_pc_increment <= 1;
            end
            default: begin
              // Do nothing
            end
          endcase
        end

        12'hFEX: begin
          casex (opcode[3:0])
            4'b00XX: {microcode_start_addr, cycle_length} <= {7'd89, CYCLE5};  // LD SPH, r
            4'b01XX: {microcode_start_addr, cycle_length} <= {7'd90, CYCLE5};  // LD r, SPH

            4'b1000: begin  // JPBA
              {microcode_start_addr, cycle_length} <= {7'd91, CYCLE5};

              skip_pc_increment <= 1;
            end
            default: begin
              // Do nothing
            end
          endcase
        end

        12'hFFX: begin
          casex (opcode[3:0])
            4'b00XX: {microcode_start_addr, cycle_length} <= {7'd92, CYCLE5};  // LD SPL, r
            4'b01XX: {microcode_start_addr, cycle_length} <= {7'd93, CYCLE5};  // LD r, SPL

            4'b1000: {microcode_start_addr, cycle_length} <= {7'd94, CYCLE5};  // HALT
            4'b1001: {microcode_start_addr, cycle_length} <= {7'd95, CYCLE5};  // SLP
            4'b1011: {microcode_start_addr, cycle_length} <= {7'd96, CYCLE5};  // NOP5
            4'b1111: {microcode_start_addr, cycle_length} <= {7'd97, CYCLE7};  // NOP7
            default: begin
              // Do nothing
            end
          endcase
        end
        default: begin
          // Do nothing
        end
      endcase
    end
  end

endmodule
