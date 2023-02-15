`include "vunit_defines.svh"

module ld_tb;
  parameter r = 0;
  parameter q = 0;

  bench bench();

  `TEST_SUITE begin
    `TEST_CASE_SETUP begin
      bench.initialize();
    end

    `TEST_CASE("LD X e should load 8 bit immediate") begin
      bench.rom_data = 12'hB69; // LD X, e

      bench.run_until_complete();
      #1;
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, 12'h269, bench.prev_y, bench.prev_sp);
      bench.assert_cycle_length(5);
    end

    `TEST_CASE("LD Y e should load 8 bit immediate") begin
      bench.rom_data = 12'h8F3; // LD Y, e

      bench.run_until_complete();
      #1;
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, 12'h3F3, bench.prev_sp);
      bench.assert_cycle_length(5);
    end

    `TEST_CASE("LBPX MX e should load 8 bit immediate into M(X) and increment X by 2") begin
      bench.rom_data = 12'h94B; // LBPX MX, e

      bench.run_until_complete();
      #1;
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x + 2, bench.prev_y, bench.prev_sp);
      bench.assert_cycle_length(5);

      bench.assert_ram(bench.prev_x, 4'hB);
      bench.assert_ram(bench.prev_x + 1, 4'h4);
    end

    `TEST_CASE("GENr LD r i should load r with 4 bit immediate") begin
      bench.rom_data = 12'hE05 | (r << 4); // LD r, i

      bench.run_until_complete();
      #1;
      bench.assert_expected(bench.prev_pc + 1, r == 0 ? 4'h5 : bench.prev_a, r == 1 ? 4'h5 : bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);
      bench.assert_cycle_length(5);

      bench.assert_ram(bench.cpu_uut.regs.x, r == 2 ? 4'h5 : 0);
      bench.assert_ram(bench.cpu_uut.regs.y, r == 3 ? 4'h5 : 0);
    end

    `TEST_CASE("LDPX MX i should load 4 bit immediate into M(X) and increment X") begin
      bench.rom_data = 12'hE6A; // LDPX MX, i

      bench.run_until_complete();
      #1;
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x + 1, bench.prev_y, bench.prev_sp);
      bench.assert_cycle_length(5);

      bench.assert_ram(bench.prev_x, 4'hA);
    end

    `TEST_CASE("LDPY MY i should load 4 bit immediate into M(Y) and increment Y") begin
      bench.rom_data = 12'hE75; // LDPX MY, i

      bench.run_until_complete();
      #1;
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y + 1, bench.prev_sp);
      bench.assert_cycle_length(5);

      bench.assert_ram(bench.prev_y, 4'h5);
    end

    `TEST_CASE("GENr LD XP r should load XP with r") begin
      reg [3:0] r_value;

      bench.rom_data = 12'hE80 | r; // LD XP, r

      r_value = bench.get_r_value(r);

      bench.run_until_complete();
      #1;
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, (bench.prev_x & 12'h0FF) | (r_value << 8), bench.prev_y, bench.prev_sp);
    end

    `TEST_CASE("GENr LD XH r should load XH with r") begin
      reg [3:0] r_value;

      bench.rom_data = 12'hE84 | r; // LD XH, r

      r_value = bench.get_r_value(r);

      bench.run_until_complete();
      #1;
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, (bench.prev_x & 12'hF0F) | (r_value << 4), bench.prev_y, bench.prev_sp);
    end

    `TEST_CASE("GENr LD XL r should load XL with r") begin
      reg [3:0] r_value;

      bench.rom_data = 12'hE88 | r; // LD XL, r

      r_value = bench.get_r_value(r);

      bench.run_until_complete();
      #1;
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, (bench.prev_x & 12'hFF0) | r_value, bench.prev_y, bench.prev_sp);
    end

    `TEST_CASE("GENr LD YP r should load YP with r") begin
      reg [3:0] r_value;

      bench.rom_data = 12'hE90 | r; // LD YP, r

      r_value = bench.get_r_value(r);

      bench.run_until_complete();
      #1;
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, (bench.prev_y & 12'h0FF) | (r_value << 8), bench.prev_sp);
    end

    `TEST_CASE("GENr LD YH r should load YH with r") begin
      reg [3:0] r_value;

      bench.rom_data = 12'hE94 | r; // LD YH, r

      r_value = bench.get_r_value(r);

      bench.run_until_complete();
      #1;
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, (bench.prev_y & 12'hF0F) | (r_value << 4), bench.prev_sp);
    end

    `TEST_CASE("GENr LD YL r should load YL with r") begin
      reg [3:0] r_value;

      bench.rom_data = 12'hE98 | r; // LD YL, r

      r_value = bench.get_r_value(r);

      bench.run_until_complete();
      #1;
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, (bench.prev_y & 12'hFF0) | r_value, bench.prev_sp);
    end

    `TEST_CASE("GENr LD r XP should load r with XP") begin
      reg [3:0] value;

      bench.rom_data = 12'hEA0 | r; // LD r, XP

      bench.cpu_uut.regs.x = 12'hACF;
      bench.cpu_uut.regs.y = 12'h48E;
      bench.update_prevs();

      value = 4'hA;

      bench.run_until_complete();
      #1;
      bench.assert_expected(bench.prev_pc + 1, r == 0 ? value : bench.prev_a, r == 1 ? value : bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);

      bench.assert_ram(bench.cpu_uut.regs.x, r == 2 ? value : 4'h0);
      bench.assert_ram(bench.cpu_uut.regs.y, r == 3 ? value : 4'h0);
    end

    `TEST_CASE("GENr LD r XH should load r with XH") begin
      reg [3:0] value;

      bench.rom_data = 12'hEA4 | r; // LD r, XH

      bench.cpu_uut.regs.x = 12'hACF;
      bench.cpu_uut.regs.y = 12'h48E;
      bench.update_prevs();

      value = 4'hC;

      bench.run_until_complete();
      #1;
      bench.assert_expected(bench.prev_pc + 1, r == 0 ? value : bench.prev_a, r == 1 ? value : bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);

      bench.assert_ram(bench.cpu_uut.regs.x, r == 2 ? value : 4'h0);
      bench.assert_ram(bench.cpu_uut.regs.y, r == 3 ? value : 4'h0);
    end

    `TEST_CASE("GENr LD r XL should load r with XL") begin
      reg [3:0] value;

      bench.rom_data = 12'hEA8 | r; // LD r, XL

      bench.cpu_uut.regs.x = 12'hACF;
      bench.cpu_uut.regs.y = 12'h48E;
      bench.update_prevs();

      value = 4'hF;

      bench.run_until_complete();
      #1;
      bench.assert_expected(bench.prev_pc + 1, r == 0 ? value : bench.prev_a, r == 1 ? value : bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);

      bench.assert_ram(bench.cpu_uut.regs.x, r == 2 ? value : 4'h0);
      bench.assert_ram(bench.cpu_uut.regs.y, r == 3 ? value : 4'h0);
    end

    `TEST_CASE("GENr LD r YP should load r with YP") begin
      reg [3:0] value;

      bench.rom_data = 12'hEB0 | r; // LD r, YP

      bench.cpu_uut.regs.x = 12'hACF;
      bench.cpu_uut.regs.y = 12'h48E;
      bench.update_prevs();

      value = 4'h4;

      bench.run_until_complete();
      #1;
      bench.assert_expected(bench.prev_pc + 1, r == 0 ? value : bench.prev_a, r == 1 ? value : bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);

      bench.assert_ram(bench.cpu_uut.regs.x, r == 2 ? value : 4'h0);
      bench.assert_ram(bench.cpu_uut.regs.y, r == 3 ? value : 4'h0);
    end

    `TEST_CASE("GENr LD r YH should load r with YH") begin
      reg [3:0] value;

      bench.rom_data = 12'hEB4 | r; // LD r, YH

      bench.cpu_uut.regs.x = 12'hACF;
      bench.cpu_uut.regs.y = 12'h48E;
      bench.update_prevs();

      value = 4'h8;

      bench.run_until_complete();
      #1;
      bench.assert_expected(bench.prev_pc + 1, r == 0 ? value : bench.prev_a, r == 1 ? value : bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);

      bench.assert_ram(bench.cpu_uut.regs.x, r == 2 ? value : 4'h0);
      bench.assert_ram(bench.cpu_uut.regs.y, r == 3 ? value : 4'h0);
    end

    `TEST_CASE("GENr LD r YL should load r with YL") begin
      reg [3:0] value;

      bench.rom_data = 12'hEB8 | r; // LD r, YL

      bench.cpu_uut.regs.x = 12'hACF;
      bench.cpu_uut.regs.y = 12'h48E;
      bench.update_prevs();

      value = 4'hE;

      bench.run_until_complete();
      #1;
      bench.assert_expected(bench.prev_pc + 1, r == 0 ? value : bench.prev_a, r == 1 ? value : bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);

      bench.assert_ram(bench.cpu_uut.regs.x, r == 2 ? value : 4'h0);
      bench.assert_ram(bench.cpu_uut.regs.y, r == 3 ? value : 4'h0);
    end

    `TEST_CASE("GENrq LD r q should load r with q") begin
      reg [3:0] value;

      bench.rom_data = 12'hEC0 | (r << 2) | q; // LD r, q

      bench.cpu_uut.regs.a = 4'h0;
      bench.cpu_uut.regs.b = 4'h5;
      bench.ram[bench.cpu_uut.regs.x] = 4'hA;
      bench.ram[bench.cpu_uut.regs.y] = 4'hF;
      bench.update_prevs();

      value = bench.get_r_value(q);

      bench.run_until_complete();
      #1;
      bench.assert_expected(bench.prev_pc + 1, r == 0 ? value : bench.prev_a, r == 1 ? value : bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);

      bench.assert_ram(bench.cpu_uut.regs.x, r == 2 ? value : 4'hA);
      bench.assert_ram(bench.cpu_uut.regs.y, r == 3 ? value : 4'hF);
    end

    `TEST_CASE("GENrq LDPX r q should load r with q and increment X") begin
      reg [3:0] value;

      bench.rom_data = 12'hEE0 | (r << 2) | q; // LDPX r, q

      bench.cpu_uut.regs.a = 4'h0;
      bench.cpu_uut.regs.b = 4'h5;
      bench.ram[bench.cpu_uut.regs.x] = 4'hA;
      bench.ram[bench.cpu_uut.regs.y] = 4'hF;
      bench.update_prevs();

      value = bench.get_r_value(q);

      bench.run_until_complete();
      #1;
      bench.assert_expected(bench.prev_pc + 1, r == 0 ? value : bench.prev_a, r == 1 ? value : bench.prev_b, bench.prev_x + 1, bench.prev_y, bench.prev_sp);

      bench.assert_ram(bench.prev_x, r == 2 ? value : 4'hA);
      bench.assert_ram(bench.prev_y, r == 3 ? value : 4'hF);
    end

    `TEST_CASE("GENrq LDPY r q should load r with q and increment Y") begin
      reg [3:0] value;

      bench.rom_data = 12'hEF0 | (r << 2) | q; // LDPY r, q

      bench.cpu_uut.regs.a = 4'h0;
      bench.cpu_uut.regs.b = 4'h5;
      bench.ram[bench.cpu_uut.regs.x] = 4'hA;
      bench.ram[bench.cpu_uut.regs.y] = 4'hF;
      bench.update_prevs();

      value = bench.get_r_value(q);

      bench.run_until_complete();
      #1;
      bench.assert_expected(bench.prev_pc + 1, r == 0 ? value : bench.prev_a, r == 1 ? value : bench.prev_b, bench.prev_x, bench.prev_y + 1, bench.prev_sp);

      bench.assert_ram(bench.prev_x, r == 2 ? value : 4'hA);
      bench.assert_ram(bench.prev_y, r == 3 ? value : 4'hF);
    end
  end;

  // The watchdog macro is optional, but recommended. If present, it
  // must not be placed inside any initial or always-block.
  `WATCHDOG(1ns);
endmodule
