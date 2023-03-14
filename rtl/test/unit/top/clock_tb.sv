`include "vunit_defines.svh"

module clock_tb;
  bench bench();

  `TEST_SUITE begin
    `TEST_CASE("Clock interrupt factor should be set") begin
      bench.initialize(12'hEE0); // INC X

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
      bench.initialize(12'hFFF); // NOP7

      // 8hz: 16384ps + 4ps
      #16388;
      #1; // Wait extra tick for data to change
      `CHECK_EQUAL(bench.cpu_uut.clock_factor, 4'b0011);

      bench.run_until_final_stage_fetch();
      bench.rom_data = 12'hEC2; // LD A, MX

      bench.run_until_complete();
      bench.cpu_uut.core.regs.x = 12'hF00;

      bench.run_until_complete();
      #1;
      bench.assert_a(4'b0011); // A should have the clock factor
      `CHECK_EQUAL(bench.cpu_uut.clock_factor, 4'b0); // Clock factor should be empty
    end

    `TEST_CASE("Interrupt factor AND with mask should produce interrupts") begin
      bench.initialize(12'hFFF); // NOP7
      bench.cpu_uut.core.regs.interrupt = 1;
      bench.cpu_uut.clock_mask = 4'b0001;

      // 32hz: 4096ps + 4ps
      #4100;
      #1;
      `CHECK_EQUAL(bench.cpu_uut.clock_factor, 4'b0001);

      bench.run_until_complete();
      #1;
      // Interrupt should begin processing
      `CHECK_EQUAL(bench.cpu_uut.core.microcode.performing_interrupt, 1);

      bench.run_until_complete();
      #1;
      bench.assert_pc(13'h0102);
    end

    `TEST_CASE("Interrupts should not be produced if factor AND mask is 0") begin
      bench.initialize(12'hFFF); // NOP7
      bench.cpu_uut.core.regs.interrupt = 1;
      bench.cpu_uut.clock_mask = 4'b0100;

      // 32hz: 4096ps + 4ps
      #4100;
      #1;
      `CHECK_EQUAL(bench.cpu_uut.clock_factor, 4'b0001);

      bench.run_until_complete();
      #1;
      // Interrupt should NOT begin processing
      `CHECK_EQUAL(bench.cpu_uut.core.microcode.performing_interrupt, 0);

      // 8hz: 16384ps - 4102ps
      #12282;
      `CHECK_EQUAL(bench.cpu_uut.clock_factor, 4'b0011);

      bench.run_until_complete();
      #1;
      // Interrupt should NOT begin processing
      `CHECK_EQUAL(bench.cpu_uut.core.microcode.performing_interrupt, 0);

      // 2hz: 65536ps - 16384ps
      #49152;
      #1;
      `CHECK_EQUAL(bench.cpu_uut.clock_factor, 4'b0111);

      // Interrupt should begin processing
      `CHECK_EQUAL(bench.cpu_uut.core.microcode.performing_interrupt, 1);

      bench.run_until_complete();
      #1;
      bench.assert_pc(13'h0102);
    end

    `TEST_CASE("Reading/writing from 0xF10 should read/write mask settings") begin
      bench.initialize(12'hEC8); // LD MX, A
      bench.cpu_uut.core.regs.a = 4'hC;
      bench.cpu_uut.core.regs.x = 12'hF10;

      bench.run_until_final_stage_fetch();
      bench.rom_data = 12'hEC6; // LD B, MX

      bench.run_until_complete();
      #1;
      `CHECK_EQUAL(bench.cpu_uut.clock_mask, 4'hC);

      bench.run_until_complete();
      #1;
      bench.assert_b(4'hC);
    end

    `TEST_CASE("Reading from 0xF20 should return current timer data from 16-128Hz") begin
      bench.initialize(12'hFFF); // NOP7

      // 32hz: 4096ps - 40ps
      #4056;
      `CHECK_EQUAL(bench.cpu_uut.clock_factor, 4'b0000);

      bench.run_until_final_stage_fetch();
      bench.rom_data = 12'hEC2; // LD A, MX

      bench.run_until_complete();
      bench.cpu_uut.core.regs.x = 12'hF20;

      bench.run_until_complete();
      #1;
      bench.assert_a(4'b0111);
    end

    `TEST_CASE("Reading from 0xF21 should return current timer data from 1-8Hz") begin
      bench.initialize(12'hFFF); // NOP7

      // 4hz: 32768ps - 40ps
      #32728;
      `CHECK_EQUAL(bench.cpu_uut.clock_factor, 4'b0011);

      bench.run_until_final_stage_fetch();
      bench.rom_data = 12'hEC2; // LD A, MX

      bench.run_until_complete();
      bench.cpu_uut.core.regs.x = 12'hF21;

      bench.run_until_complete();
      #1;
      bench.assert_a(4'b0011);
    end

    `TEST_CASE("Writing to 0xF76 bit 1 will reset timer") begin
      bench.initialize(12'hFFF); // NOP7

      // 8hz: 16384ps + 4ps
      #16388;
      #1; // Wait extra tick for data to change
      `CHECK_EQUAL(bench.cpu_uut.clock_factor, 4'b0011);
      
      bench.run_until_final_stage_fetch();
      bench.rom_data = 12'hEC8; // LD MX, A

      bench.run_until_complete();
      bench.cpu_uut.core.regs.a = 4'h2;
      bench.cpu_uut.core.regs.x = 12'hF76;

      bench.run_until_final_stage_fetch();
      bench.rom_data = 12'hFFF; // NOP7

      bench.run_until_complete();
      bench.cpu_uut.interrupt.clock_factor = 4'h0;
      #4;
      #1;
      `CHECK_EQUAL(bench.cpu_uut.timers.clock.counter_256, 4'b0);
      `CHECK_EQUAL(bench.cpu_uut.timers.clock.divider, 4'b0);

      // 8hz: 16384ps + 4ps - 5ps + 12ps
      #16395;
      #1; // Wait extra tick for data to change
      `CHECK_EQUAL(bench.cpu_uut.clock_factor, 4'b0011);
    end

    `TEST_CASE("Writing to 0xF76 bits besides 1 will not reset timer") begin
      bench.initialize(12'hFFF); // NOP7

      // 8hz: 16384ps + 4ps
      #16388;
      #1; // Wait extra tick for data to change
      `CHECK_EQUAL(bench.cpu_uut.clock_factor, 4'b0011);

      bench.run_until_final_stage_fetch();
      bench.rom_data = 12'hEC8; // LD MX, A

      bench.run_until_complete();
      bench.cpu_uut.core.regs.a = 4'hD;
      bench.cpu_uut.core.regs.x = 12'hF76;

      bench.run_until_final_stage_fetch();
      bench.rom_data = 12'hFFF; // NOP7

      bench.run_until_complete();
      #4;
      #1;
      `CHECK_NOT_EQUAL(bench.cpu_uut.timers.clock.counter_256, 4'b0);
      `CHECK_NOT_EQUAL(bench.cpu_uut.timers.clock.divider, 4'b0);
    end
  end;

  // The watchdog macro is optional, but recommended. If present, it
  // must not be placed inside any initial or always-block.
  `WATCHDOG(500ns);
endmodule
