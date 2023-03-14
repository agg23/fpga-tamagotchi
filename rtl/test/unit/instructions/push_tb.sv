`include "vunit_defines.svh"

module push_tb;
  parameter r = 0;

  core_bench bench();

  task test_push(reg [11:0] opcode, reg [3:0] expected, reg use_r, reg [3:0] flags);
    reg [3:0] value;
  
    bench.initialize(opcode);

    bench.cpu_uut.regs.x = 12'hABC;
    bench.cpu_uut.regs.y = 12'h789;

    bench.cpu_uut.regs.a = 4'h4;
    bench.cpu_uut.regs.b = 4'h7;
    bench.ram[bench.cpu_uut.regs.x] = 4'hA;
    bench.ram[bench.cpu_uut.regs.y] = 4'hF;

    bench.cpu_uut.regs.carry = flags[0];
    bench.cpu_uut.regs.zero = flags[1];
    bench.cpu_uut.regs.decimal = flags[2];
    bench.cpu_uut.regs.interrupt = flags[3];
    bench.update_prevs();

    if (use_r) begin
      value = bench.get_r_value(r);
    end else begin
      value = expected;
    end

    bench.run_until_complete();
    #1;
    bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp - 1);
    bench.assert_cycle_length(5);

    bench.assert_ram(bench.prev_sp - 1, value);
  endtask

  `TEST_SUITE begin
    `TEST_CASE("GENr PUSH r should push r to stack") begin
      reg [11:0] opcode;

      opcode = 12'hFC0 | r; // PUSH r

      test_push(opcode, 4'h0, 1, 0);
    end

    `TEST_CASE("PUSH XP should push XP to stack") begin
      test_push(12'hFC4, 4'hA, 0, 0);
    end

    `TEST_CASE("PUSH XH should push XH to stack") begin
      test_push(12'hFC5, 4'hB, 0, 0);
    end

    `TEST_CASE("PUSH XL should push XL to stack") begin
      test_push(12'hFC6, 4'hC, 0, 0);
    end

    `TEST_CASE("PUSH YP should push YP to stack") begin
      test_push(12'hFC7, 4'h7, 0, 0);
    end

    `TEST_CASE("PUSH YH should push YH to stack") begin
      test_push(12'hFC8, 4'h8, 0, 0);
    end

    `TEST_CASE("PUSH YL should push YL to stack") begin
      test_push(12'hFC9, 4'h9, 0, 0);
    end

    `TEST_CASE("PUSH F should push flags to stack") begin
      // Set interrupt and zero flags
      test_push(12'hFCA, 4'hA, 0, 4'b1010);
    end
  end;

  // The watchdog macro is optional, but recommended. If present, it
  // must not be placed inside any initial or always-block.
  `WATCHDOG(1ns);
endmodule
