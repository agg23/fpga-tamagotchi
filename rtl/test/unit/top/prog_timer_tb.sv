`include "vunit_defines.svh"

module prog_timer_tb;
  bench bench();

  task test_single_tick_duration(reg [2:0] clock_selection, int duration);
    bench.initialize(12'hFFF); // NOP7
    bench.cpu_uut.enable_prog_timer = 1;
    bench.cpu_uut.prog_timer_clock_selection = clock_selection;
    bench.cpu_uut.prog_timer_reload = 8'h1;
    bench.cpu_uut.timers.prog_timer.downcounter = 8'h1;

    // Wait for first tick
    // + 12 cycle delay
    #(duration);
    `CHECK_EQUAL(bench.cpu_uut.prog_timer_factor, 0);
    #12;
    #1;

    `CHECK_EQUAL(bench.cpu_uut.prog_timer_factor, 1);
    bench.cpu_uut.timers.prog_timer.factor_flags = 0;

    // Test second tick
    #(duration);

    `CHECK_EQUAL(bench.cpu_uut.prog_timer_factor, 1);
  endtask

  `TEST_SUITE begin
    `TEST_CASE("Timer should fire at 256Hz when 0xF79 set to 2") begin
      test_single_tick_duration(3'h2, 512);
    end

    `TEST_CASE("Timer should fire at 512Hz when 0xF79 set to 3") begin
      test_single_tick_duration(3'h3, 256);
    end

    `TEST_CASE("Timer should fire at 1024Hz when 0xF79 set to 4") begin
      test_single_tick_duration(3'h4, 128);
    end

    `TEST_CASE("Timer should fire at 2048Hz when 0xF79 set to 5") begin
      test_single_tick_duration(3'h5, 64);
    end

    `TEST_CASE("Timer should fire at 4096Hz when 0xF79 set to 6") begin
      test_single_tick_duration(3'h6, 32);
    end

    `TEST_CASE("Timer should fire at 8192Hz when 0xF79 set to 7") begin
      test_single_tick_duration(3'h7, 16);
    end

    `TEST_CASE("Timer should fire after full duration at tick rate has passed") begin
      bench.initialize(12'hFFF); // NOP7
      bench.cpu_uut.enable_prog_timer = 1;

      // 1024Hz, 200 ticks
      bench.cpu_uut.prog_timer_clock_selection = 3'h4;
      bench.cpu_uut.prog_timer_reload = 8'd200;
      bench.cpu_uut.timers.prog_timer.downcounter = 8'd200;

      // 32 * 200 * 4ps + 12
      #25612;
      #1;

      `CHECK_EQUAL(bench.cpu_uut.prog_timer_factor, 4'b0001);
      
      // It should immediately reload and start timing again
      `CHECK_EQUAL(bench.cpu_uut.timers.prog_timer.downcounter, 8'd200);
      bench.cpu_uut.timers.prog_timer.factor_flags = 0;

      #25600;

      `CHECK_EQUAL(bench.cpu_uut.prog_timer_factor, 4'b0001);
    end

    `TEST_CASE("Reading from 0xF24 and 0xF25 should return current downcounter state") begin
      bench.initialize(12'hFFF); // NOP7
      bench.cpu_uut.enable_prog_timer = 1;

      // 1024Hz, 200 ticks
      bench.cpu_uut.prog_timer_clock_selection = 3'h4;
      bench.cpu_uut.prog_timer_reload = 8'd200;
      bench.cpu_uut.timers.prog_timer.downcounter = 8'd200;

      // Go to 123 steps in the timer, so 200 - 123 = 77: 0x4D
      // 32 * 123 * 4ps + 12
      #15756;
      #1;

      bench.run_until_final_stage_fetch();
      bench.rom_data = 12'hEC2; // LD A, MX

      bench.run_until_complete();
      bench.cpu_uut.core.regs.x = 12'hF24;

      bench.run_until_complete();
      bench.cpu_uut.core.regs.x = 12'hF25;

      #1;
      // Lower nibble of counter
      bench.assert_a(4'hD);

      bench.run_until_complete();
      #1;
      // Higher nibble of counter
      bench.assert_a(4'h4);
    end

    `TEST_CASE("Reading from 0xF26 and 0xF27 should read the reload data") begin
      bench.initialize(12'hEC2); // LD A, MX
      bench.cpu_uut.core.regs.x = 12'hF26;
      bench.cpu_uut.prog_timer_reload = 8'h8A;

      #1;

      // Low nibble
      bench.run_until_complete();
      bench.cpu_uut.core.regs.x = 12'hF27;
      #1;
      bench.assert_a(4'hA);

      // High nibble
      bench.run_until_complete();
      #1;
      bench.assert_a(4'h8);
    end

    `TEST_CASE("Writing to 0xF26 and 0xF27 should set the reload data") begin
      bench.initialize(12'hEC8); // LD MX, A
      bench.cpu_uut.core.regs.a = 4'h5;
      bench.cpu_uut.core.regs.x = 12'hF26;

      #1;

      // Set low nibble
      bench.run_until_complete();
      bench.cpu_uut.core.regs.a = 4'hF;
      bench.cpu_uut.core.regs.x = 12'hF27;

      // Set high nibble
      bench.run_until_complete();
      #1;

      `CHECK_EQUAL(bench.cpu_uut.prog_timer_reload, 8'hF5);
    end

    `TEST_CASE("Reading/writing from 0xF79 should read/write the selected clock") begin 
      bench.initialize(12'hEC8); // LD MX, A
      bench.cpu_uut.core.regs.a = 4'hA;
      bench.cpu_uut.core.regs.x = 12'hF79;

      bench.run_until_final_stage_fetch();
      bench.rom_data = 12'hEC6; // LD B, MX

      bench.run_until_complete();
      #1;
      `CHECK_EQUAL(bench.cpu_uut.prog_timer_clock_selection, 3'h2);

      bench.run_until_complete();
      #1;
      bench.assert_b(4'hA);
    end

    `TEST_CASE("Timer should only start once 0xF78 bit 0 is set") begin
      bench.initialize(12'hFFF); // NOP7

      // 512Hz, 183 ticks
      bench.cpu_uut.prog_timer_clock_selection = 3'h3;
      bench.cpu_uut.prog_timer_reload = 8'd183;
      bench.cpu_uut.timers.prog_timer.downcounter = 8'd183;

      // Check 70 steps in
      // 64 * 70 * 4ps + 12
      #17932;
      #1;

      `CHECK_EQUAL(bench.cpu_uut.timers.prog_timer.downcounter, 8'd183);

      bench.run_until_final_stage_fetch();
      bench.rom_data = 12'hEC8; // LD MX, A

      bench.run_until_complete();
      bench.cpu_uut.core.regs.a = 4'b0011;
      bench.cpu_uut.core.regs.x = 12'hF78;
      
      bench.run_until_final_stage_fetch();
      bench.rom_data = 12'hFFF; // NOP7

      bench.run_until_complete();
      #1;
      `CHECK_EQUAL(bench.cpu_uut.enable_prog_timer, 1);

      #17920;
      #1;

      `CHECK_EQUAL(bench.cpu_uut.timers.prog_timer.downcounter, 8'd113);
    end

    `TEST_CASE("Timer should pause on 0xF78 bit 0 clear and resume on bit 0 set") begin
      bench.initialize(12'hFFF); // NOP7
      bench.cpu_uut.enable_prog_timer = 1;

      // 512Hz, 183 ticks
      bench.cpu_uut.prog_timer_clock_selection = 3'h3;
      bench.cpu_uut.prog_timer_reload = 8'd183;
      bench.cpu_uut.timers.prog_timer.downcounter = 8'd183;

      // Check 70 steps in
      // 64 * 70 * 4ps + 12
      #17932;
      #1;

      `CHECK_EQUAL(bench.cpu_uut.timers.prog_timer.downcounter, 8'd113);

      // Disable timer
      bench.run_until_final_stage_fetch();
      bench.rom_data = 12'hEC8; // LD MX, A

      bench.run_until_complete();
      bench.cpu_uut.core.regs.a = 4'b0000;
      bench.cpu_uut.core.regs.x = 12'hF78;

      bench.run_until_final_stage_fetch();
      bench.rom_data = 12'hFFF; // NOP7

      bench.run_until_complete();

      #1;
      `CHECK_EQUAL(bench.cpu_uut.enable_prog_timer, 0);

      // 64 * 70 * 4ps
      #17920;

      `CHECK_EQUAL(bench.cpu_uut.timers.prog_timer.downcounter, 8'd113);

      // Start stopwatch
      bench.run_until_final_stage_fetch();
      bench.rom_data = 12'hEC8; // LD MX, A

      bench.run_until_complete();
      bench.cpu_uut.core.regs.a = 4'b0001;
      bench.cpu_uut.core.regs.x = 12'hF78;

      bench.run_until_final_stage_fetch();
      bench.rom_data = 12'hFFF; // NOP7

      bench.run_until_complete();

      #1;
      `CHECK_EQUAL(bench.cpu_uut.enable_prog_timer, 1);

      // 64 * 70 * 4ps
      #17920;

      `CHECK_EQUAL(bench.cpu_uut.timers.prog_timer.downcounter, 8'd43);
    end

    `TEST_CASE("Timer should reset on 0xF78 bit 1 set") begin
      bench.initialize(12'hFFF); // NOP7
      bench.cpu_uut.enable_prog_timer = 1;

      // 512Hz, 183 ticks
      bench.cpu_uut.prog_timer_clock_selection = 3'h3;
      bench.cpu_uut.prog_timer_reload = 8'd183;
      bench.cpu_uut.timers.prog_timer.downcounter = 8'd183;

      // 64 * 70 * 4ps
      #17932;
      #1;

      `CHECK_EQUAL(bench.cpu_uut.timers.prog_timer.downcounter, 8'd113);

      bench.run_until_final_stage_fetch();
      bench.rom_data = 12'hEC8; // LD MX, A

      bench.run_until_complete();
      bench.cpu_uut.core.regs.a = 4'b0011;
      bench.cpu_uut.core.regs.x = 12'hF78;

      bench.run_until_final_stage_fetch();
      bench.rom_data = 12'hFFF; // NOP7

      bench.run_until_complete();

      #10;

      `CHECK_EQUAL(bench.cpu_uut.timers.prog_timer.downcounter, 8'd183);

      // 64 * 70 * 4ps
      #17920;

      `CHECK_EQUAL(bench.cpu_uut.timers.prog_timer.downcounter, 8'd113);
    end

    `TEST_CASE("Reading 0xF02 should get factor flags and clear them") begin
      bench.initialize(12'hFFF); // NOP7
      bench.cpu_uut.enable_prog_timer = 1;

      // 512Hz, 183 ticks
      bench.cpu_uut.prog_timer_clock_selection = 3'h3;
      bench.cpu_uut.prog_timer_reload = 8'd183;
      bench.cpu_uut.timers.prog_timer.downcounter = 8'd183;

      `CHECK_EQUAL(bench.cpu_uut.prog_timer_factor, 4'b0000);

      // 64 * 183 * 4ps + 12
      #46860;
      #1;

      `CHECK_EQUAL(bench.cpu_uut.prog_timer_factor, 4'b0001);

      bench.run_until_final_stage_fetch();
      bench.rom_data = 12'hEC2; // LD A, MX

      bench.run_until_complete();
      bench.cpu_uut.core.regs.x = 12'hF02;

      bench.run_until_final_stage_fetch();
      bench.rom_data = 12'hFFF; // NOP7

      bench.run_until_complete();
      #1;
      bench.assert_a(4'h1);
      `CHECK_EQUAL(bench.cpu_uut.prog_timer_factor, 4'b00);
    end

    `TEST_CASE("Interrupt factor AND with mask should produce interrupts") begin
      bench.initialize(12'hFFF); // NOP7
      bench.cpu_uut.core.regs.interrupt = 1;
      bench.cpu_uut.enable_prog_timer = 1;
      bench.cpu_uut.prog_timer_mask = 1;

      // 512Hz, 183 ticks
      bench.cpu_uut.prog_timer_clock_selection = 3'h3;
      bench.cpu_uut.prog_timer_reload = 8'd183;
      bench.cpu_uut.timers.prog_timer.downcounter = 8'd183;

      // 64 * 183 * 4ps + 12
      #46860;
      #1;

      `CHECK_EQUAL(bench.cpu_uut.prog_timer_factor, 4'b0001);

      bench.run_until_complete();
      #1;
      // Interrupt should begin processing
      `CHECK_EQUAL(bench.cpu_uut.core.microcode.performing_interrupt, 1);

      bench.run_until_complete();
      #1;
      bench.assert_pc(13'h010C);
    end

    `TEST_CASE("Interrupts should not be produced if factor AND mask is 0") begin
      bench.initialize(12'hFFF); // NOP7
      bench.cpu_uut.core.regs.interrupt = 1;
      bench.cpu_uut.enable_prog_timer = 1;
      bench.cpu_uut.prog_timer_mask = 0;

      // 512Hz, 183 ticks
      bench.cpu_uut.prog_timer_clock_selection = 3'h3;
      bench.cpu_uut.prog_timer_reload = 8'd183;
      bench.cpu_uut.timers.prog_timer.downcounter = 8'd183;

      // 64 * 183 * 4ps + 12
      #46860;
      #1;

      `CHECK_EQUAL(bench.cpu_uut.prog_timer_factor, 4'b0001);

      bench.run_until_complete();
      #1;
      // Interrupt should not begin processing
      `CHECK_EQUAL(bench.cpu_uut.core.microcode.performing_interrupt, 0);
    end

    `TEST_CASE("Reading/writing from 0xF12 should read/write mask settings") begin
      bench.initialize(12'hEC8); // LD MX, A
      bench.cpu_uut.core.regs.a = 4'h5;
      bench.cpu_uut.core.regs.x = 12'hF12;

      bench.run_until_final_stage_fetch();
      bench.rom_data = 12'hEC6; // LD B, MX

      bench.run_until_complete();
      #1;
      `CHECK_EQUAL(bench.cpu_uut.prog_timer_mask, 1);

      bench.run_until_complete();
      #1;
      bench.assert_b(4'h1);
    end
  end;

  // The watchdog macro is optional, but recommended. If present, it
  // must not be placed inside any initial or always-block.
  `WATCHDOG(500ns);
endmodule
