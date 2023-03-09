`include "vunit_defines.svh"

module savestates_tb;
  bench bench();

  `TEST_SUITE begin
    `TEST_CASE_SETUP begin
      bench.initialize();
    end

    `TEST_CASE("Registers should initalize to expected defaults") begin
      bench.rom_data = 12'hFFF; // NOP7

      // Reload SS buffers with default values
      bench.ss_bus_reset_n = 0;
      // Reinitialize all process blocks
      bench.reset_n = 0;

      // Wait one cycle
      #4;

      // Release reset
      bench.ss_bus_reset_n = 1;
      bench.reset_n = 1;

      #1;

      bench.assert_expected(13'h0100, 4'h0, 4'h0, 12'h0, 12'h0, 8'h0);
      bench.assert_np(5'h01);
      bench.assert_interrupt(0);
      bench.assert_decimal(0);
      bench.assert_zero(0);
      bench.assert_carry(0);
    end

    `TEST_CASE("Registers should be set by SS addresses 0x0 and 0x1") begin
      bench.rom_data = 12'hFFF; // NOP7

      // Reinitialize all process blocks
      bench.reset_n = 0;

      #4;
      #1;

      // {2'b0, np, pc, a, b, interrupt, decimal, zero, carry}
      bench.ss_write(0, {2'b0, 5'h15, 13'h0F71, 4'h4, 4'hC, 1'b1, 1'b0, 1'b1, 1'b1});
      // {x, y, sp}
      bench.ss_write(1, {12'h325, 12'h9D1, 8'hF3});

      #4;
      bench.assert_expected(13'h0F71, 4'h4, 4'hC, 12'h325, 12'h9D1, 8'hF3);
      bench.assert_np(5'h15);
      bench.assert_interrupt(1);
      bench.assert_decimal(0);
      bench.assert_zero(1);
      bench.assert_carry(1);
    end
  end;

  // The watchdog macro is optional, but recommended. If present, it
  // must not be placed inside any initial or always-block.
  `WATCHDOG(1ns);
endmodule
