`include "vunit_defines.svh"

module input_interrupt_tb;
  bench bench();

  parameter decimal = 0;
  parameter r = 0;
  parameter q = 0;

  `TEST_SUITE begin
    `TEST_CASE_SETUP begin
      bench.initialize();
    end

    `TEST_CASE("Reading from 0xF40 and 0xF42 should return the current input values") begin
      bench.rom_data = 12'hEC2; // LD A, MX
      bench.cpu_uut.core.regs.x = 12'hF40;

      bench.input_k0 = 4'h7;
      bench.input_k1 = 4'h9;

      bench.run_until_complete();
      bench.cpu_uut.core.regs.x = 12'hF42;
      #1;
      bench.assert_a(4'h7);

      bench.run_until_complete();
      #1;
      bench.assert_a(4'h9);
    end

    `TEST_CASE("Reading/writing from 0xF41 should read/write the K0 input relation") begin
      bench.rom_data = 12'hEC8; // LD MX, A
      bench.cpu_uut.core.regs.a = 4'h5;
      bench.cpu_uut.core.regs.x = 12'hF41;

      bench.run_until_complete();
      bench.rom_data = 12'hEC6; // LD B, MX
      #1;
      `CHECK_EQUAL(bench.cpu_uut.input_relation_k0, 4'h5);

      bench.run_until_complete();
      #1;
      bench.assert_b(4'h5);
    end

    `TEST_CASE("Reading/writing from 0xF14 should read/write the K0 interrupt mask") begin
      bench.rom_data = 12'hEC8; // LD MX, A
      bench.cpu_uut.core.regs.a = 4'hA;
      bench.cpu_uut.core.regs.x = 12'hF14;

      bench.run_until_complete();
      bench.rom_data = 12'hEC6; // LD B, MX
      #1;
      `CHECK_EQUAL(bench.cpu_uut.input_k0_mask, 4'hA);

      bench.run_until_complete();
      #1;
      bench.assert_b(4'hA);
    end

    `TEST_CASE("Reading/writing from 0xF15 should read/write the K1 interrupt mask") begin
      bench.rom_data = 12'hEC8; // LD MX, A
      bench.cpu_uut.core.regs.a = 4'h3;
      bench.cpu_uut.core.regs.x = 12'hF15;

      bench.run_until_complete();
      bench.rom_data = 12'hEC6; // LD B, MX
      #1;
      `CHECK_EQUAL(bench.cpu_uut.input_k1_mask, 4'h3);

      bench.run_until_complete();
      #1;
      bench.assert_b(4'h3);
    end

    `TEST_CASE("Reading from 0xF04 and 0xF05 should return the current input interrupt factor") begin
      bench.rom_data = 12'hEC2; // LD A, MX
      bench.cpu_uut.core.regs.x = 12'hF04;

      bench.cpu_uut.input_lines.factor_flags = 2'b01;

      bench.run_until_complete();
      bench.cpu_uut.core.regs.x = 12'hF05;
      #1;
      bench.assert_a(4'h1);

      bench.run_until_complete();
      #1;
      bench.assert_a(4'h0);
    end

    `TEST_CASE("GENrqd Interrupt factor for K0 should be set based on K0 and relation") begin
      reg [3:0] input_k0;
      reg [3:0] input_k0_next;
      reg [3:0] relation;
      reg d;

      d = decimal;

      input_k0 = 0;
      input_k0_next = 0;
      relation = 0;

      bench.rom_data = 12'hFFF; // NOP7
      relation[q] = 1;
      if (~d) begin
        relation = ~relation;
      end

      input_k0[r] = d;
      input_k0_next[r] = ~d;

      bench.input_k0 = input_k0;
      bench.cpu_uut.input_relation_k0 = relation;
      bench.cpu_uut.input_k0_mask = 4'hF;

      #1;
      bench.cpu_uut.input_lines.factor_flags = 0;

      #101;
      bench.input_k0 = input_k0_next;
      #12;

      `CHECK_EQUAL(bench.cpu_uut.input_factor[0], r == q);
    end

    `TEST_CASE("GENrd Interrupt factor for K1 should be set based on falling edge of K1") begin
      reg [3:0] input_k1;
      reg [3:0] input_k1_next;
      reg d;

      d = decimal;

      input_k1 = 0;
      input_k1_next = 0;

      bench.rom_data = 12'hFFF; // NOP7

      input_k1[r] = d;
      input_k1_next[r] = ~d;

      bench.input_k1 = input_k1;
      bench.cpu_uut.input_k1_mask = 4'hF;

      #1;
      bench.cpu_uut.input_lines.factor_flags = 0;

      #101;
      bench.input_k1 = input_k1_next;
      #12;

      `CHECK_EQUAL(bench.cpu_uut.input_factor[1], d);
    end

    `TEST_CASE("GENrq Interrupt factor for K0 should only be set if mask also set") begin
      reg [3:0] input_k0;
      reg [3:0] input_k0_next;
      reg [3:0] mask;

      input_k0 = 0;
      input_k0_next = 0;
      mask = 0;

      bench.rom_data = 12'hFFF; // NOP7

      input_k0[r] = 1;
      input_k0_next[r] = 0;
      mask[q] = 1;

      bench.input_k0 = input_k0;
      bench.cpu_uut.input_k0_mask = mask;

      #1;
      bench.cpu_uut.input_lines.factor_flags = 0;

      #101;
      bench.input_k0 = input_k0_next;
      #12;

      `CHECK_EQUAL(bench.cpu_uut.input_factor[0], r == q);
    end

    `TEST_CASE("Reading 0xF04 should get K0 factor flag and clear it") begin
      bench.rom_data = 12'hFFF; // NOP7
      bench.cpu_uut.input_k0_mask = 4'hF;
      bench.input_k0 = 4'h1;

      `CHECK_EQUAL(bench.cpu_uut.input_factor, 2'b00);

      #101;
      bench.input_k0 = 0;
      #12;

      `CHECK_EQUAL(bench.cpu_uut.input_factor, 2'b01);

      bench.run_until_complete();
      bench.cpu_uut.core.regs.x = 12'hF04;
      bench.rom_data = 12'hEC2; // LD A, MX

      bench.run_until_complete();
      bench.rom_data = 12'hFFF; // NOP7
      #1;
      bench.assert_a(4'h1);
      `CHECK_EQUAL(bench.cpu_uut.input_factor, 4'b00);
    end

    `TEST_CASE("Reading 0xF05 should get K1 factor flag and clear it") begin
      bench.rom_data = 12'hFFF; // NOP7
      bench.cpu_uut.input_k1_mask = 4'hF;
      bench.input_k1 = 4'h4;

      `CHECK_EQUAL(bench.cpu_uut.input_factor, 2'b00);

      #101;
      bench.input_k1 = 0;
      #12;

      `CHECK_EQUAL(bench.cpu_uut.input_factor, 2'b10);

      bench.run_until_complete();
      bench.cpu_uut.core.regs.x = 12'hF05;
      bench.rom_data = 12'hEC2; // LD A, MX

      bench.run_until_complete();
      bench.rom_data = 12'hFFF; // NOP7
      #1;
      bench.assert_a(4'h1);
      `CHECK_EQUAL(bench.cpu_uut.input_factor, 2'b00);
    end

    `TEST_CASE("Interrupt factor should produce interrupts") begin
      bench.rom_data = 12'hFFF; // NOP7
      bench.cpu_uut.core.regs.interrupt = 1;
      bench.input_k0 = 4'h8;
      bench.cpu_uut.input_k0_mask = 4'hC;

      #84;
      bench.input_k0 = 0;
      #12;

      `CHECK_EQUAL(bench.cpu_uut.input_factor, 2'b01);

      bench.run_until_complete();
      #1;
      // Interrupt should begin processing
      `CHECK_EQUAL(bench.cpu_uut.core.microcode.performing_interrupt, 1);

      bench.run_until_complete();
      #1;
      bench.assert_pc(13'h0106);
    end
  end;

  // The watchdog macro is optional, but recommended. If present, it
  // must not be placed inside any initial or always-block.
  `WATCHDOG(500ns);
endmodule
