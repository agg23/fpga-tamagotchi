`include "vunit_defines.svh"

module timer_interrupt_tb;
  bench bench();

  `TEST_SUITE begin
    `TEST_CASE_SETUP begin
      bench.initialize();
    end

    `TEST_CASE("Clock interrupt factor should be set") begin
      bench.rom_data = 12'hEE0; // INC X

      // #4 per complete clk cycle
      // 32hz will be 1024 cycles: 1024 * 4 = 4096
      // Takes one extra cycle to assert
      #4100;
      #1; // Wait extra tick for data to change
      `CHECK_EQUAL(bench.cpu_uut.clock_factor, 4'b0001);

      // 8hz will be 4096 cycles: 4096 * 4 = 16384
      // Minus #4101 plus one extra cycle: 16384 - 4101 + 4 = 12287
      #12287;
      #1; // Wait extra tick for data to change
      `CHECK_EQUAL(bench.cpu_uut.clock_factor, 4'b0011);

      // 2hz will be 16384 cycles: 16384 * 4 = 65536
      // Minus #12288 - 4101 plus one extra cycle: 65536 - 12288 - 4101 + 4 = 49151
      #49151;
      #1; // Wait extra tick for data to change
      `CHECK_EQUAL(bench.cpu_uut.clock_factor, 4'b0111);

      // 1hz will be 32768 cycles: 32768 * 4 = 131072
      // Minus #49151 - 12288 - 4101 plus one extra cycle: 65536
      #65536;
      #1; // Wait extra tick for data to change
      `CHECK_EQUAL(bench.cpu_uut.clock_factor, 4'b1111);
    end

    `TEST_CASE("Reading from clock interrupt factor register should clear it") begin
      bench.rom_data = 12'hFFF; // NOP7

      // 8hz: 16384ps + 4ps
      #16388;
      #1; // Wait extra tick for data to change
      `CHECK_EQUAL(bench.cpu_uut.clock_factor, 4'b0011);

      bench.run_until_complete();
      bench.cpu_uut.core.regs.x = 12'hF00;
      bench.rom_data = 12'hEC2; // LD A, MX

      bench.run_until_complete();
      #1;
      bench.assert_a(4'b0011); // A should have the clock factor
      `CHECK_EQUAL(bench.cpu_uut.clock_factor, 4'b0); // Clock factor should be empty
    end

    // TODO: Interrupts should fire based on mask values
    // TODO: Timer data should be readable
    // TODO: Timer should be resetable
  end;

  // The watchdog macro is optional, but recommended. If present, it
  // must not be placed inside any initial or always-block.
  `WATCHDOG(500ns);
endmodule
