`include "vunit_defines.svh"

module ret_tb;
  bench bench();

  `TEST_SUITE begin
    `TEST_CASE("RETD should set PC and load 8 bit immediate into MX and increment X twice") begin
      bench.initialize(12'h1FC); // RETD 0xFC
      bench.cpu_uut.core.regs.x = 12'h1F1;
      bench.cpu_uut.core.regs.sp = 8'h44;
      bench.cpu_uut.ram.memory[8'h44] = 4'hD;  // PCSL
      bench.cpu_uut.ram.memory[8'h45] = 4'h4;  // PCSL
      bench.cpu_uut.ram.memory[8'h46] = 4'h7;  // PCP
      bench.update_prevs();

      #8;
      // Changing the PC value shouldn't affect the instruction
      bench.rom_data = 12'hFFF;

      bench.run_until_final_stage_fetch();
      #1;
      bench.assert_expected(13'h074D, bench.prev_a, bench.prev_b, 12'hXXX, bench.prev_y, 8'h47);

      bench.run_until_complete();
      #1;
      bench.assert_cycle_length(12);
      bench.assert_ram(12'h1F1, 4'hC); // Lower nibble of immediate
      bench.assert_ram(12'h1F2, 4'hF); // Upper nibble of immediate

      bench.assert_x(12'h1F3);
    end

    `TEST_CASE("RETS should set PC and increment it") begin
      bench.initialize(12'hFDE); // RETS
      bench.cpu_uut.core.regs.x = 12'h1F1;
      bench.cpu_uut.core.regs.sp = 8'h44;
      bench.cpu_uut.ram.memory[8'h44] = 4'hD;  // PCSL
      bench.cpu_uut.ram.memory[8'h45] = 4'h4;  // PCSL
      bench.cpu_uut.ram.memory[8'h46] = 4'h7;  // PCP
      bench.update_prevs();

      bench.run_until_final_stage_fetch();
      #1;
      bench.assert_expected(13'h074E, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, 8'h47);

      bench.run_until_complete();
      #1;
      bench.assert_cycle_length(12);
    end

    `TEST_CASE("RET should set PC") begin
      bench.initialize(12'hFDF); // RET
      bench.cpu_uut.core.regs.x = 12'h1F1;
      bench.cpu_uut.core.regs.sp = 8'h44;
      bench.cpu_uut.ram.memory[8'h44] = 4'hD;  // PCSL
      bench.cpu_uut.ram.memory[8'h45] = 4'h4;  // PCSL
      bench.cpu_uut.ram.memory[8'h46] = 4'h7;  // PCP
      bench.update_prevs();

      bench.run_until_final_stage_fetch();
      #1;
      bench.assert_expected(13'h074D, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, 8'hXX);

      bench.run_until_complete();
      #1;
      bench.assert_cycle_length(7);

      bench.assert_sp(8'h47);
    end

    `TEST_CASE("RET with SP at 0xFE should wrap to data at 0x00") begin
      bench.initialize(12'hFDF); // RET
      bench.cpu_uut.core.regs.sp = 8'hFE;
      bench.cpu_uut.ram.memory[12'h0] = 4'h1;
      bench.cpu_uut.ram.memory[12'h1] = 4'hF;
      bench.cpu_uut.ram.memory[12'hFE] = 4'h3;
      bench.cpu_uut.ram.memory[12'hFF] = 4'h2;
      bench.cpu_uut.ram.memory[12'h100] = 4'hF;
      bench.cpu_uut.ram.memory[12'h101] = 4'hF;
      bench.cpu_uut.ram.memory[12'h102] = 4'hF;

      bench.update_prevs();

      bench.run_until_complete();
      #1;
      bench.assert_pc(13'h0123);
    end

  end;

  // The watchdog macro is optional, but recommended. If present, it
  // must not be placed inside any initial or always-block.
  `WATCHDOG(1ns);
endmodule
