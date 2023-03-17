`include "vunit_defines.svh"

module bench;
  reg clk = 0;
  reg clk_2x = 1;

  reg reset = 1;

  wire [12:0] rom_addr;
  reg [11:0] rom_data = 0;

  reg [3:0] input_k0 = 0;
  reg [3:0] input_k1 = 0;

  wire [3:0] video_data;
  wire buzzer;
  wire lcd_all_off_setting;
  wire lcd_all_on_setting;

  // Savestates
  reg [31:0] ss_bus_in = 0;
  reg [7:0] ss_bus_addr = 0;
  reg ss_bus_wren = 0;
  reg ss_bus_reset = 1;
  wire [31:0] ss_bus_out;

  cpu_6s46 cpu_uut (
      .clk(clk_2x),
      .clk_en(clk),
      .clk_2x_en(clk_2x),

      .reset(reset),

      .input_k0(input_k0),
      .input_k1(input_k1),

      .rom_addr(rom_addr),
      .rom_data(rom_data),

      .video_addr(8'b0),
      .video_data(video_data),

      .buzzer(buzzer),

      .lcd_all_off_setting(lcd_all_off_setting),
      .lcd_all_on_setting (lcd_all_on_setting),

      // Savestates
      .ss_bus_in(ss_bus_in),
      .ss_bus_addr(ss_bus_addr),
      .ss_bus_wren(ss_bus_wren),
      .ss_bus_reset(ss_bus_reset),
      .ss_bus_out(ss_bus_out)
  );

  // task half_cycle();
  //   #1 clk_2x <= ~clk_2x;

  //   #1 clk <= ~clk;
  //   clk_2x <= ~clk_2x;
  // endtask

  always begin
    #1 clk_2x <= ~clk_2x;

    #1 clk <= ~clk;
    clk_2x <= ~clk_2x;
  end

  // Values for easy reference in change detection
  reg [12:0] prev_pc;
  reg [3:0] prev_a;
  reg [3:0] prev_b;

  reg [11:0] prev_x;
  reg [11:0] prev_y;

  reg [7:0] prev_sp;

  reg prev_carry;
  reg prev_zero;
  reg prev_interrupt;
  reg prev_decimal;

  reg [7:0] cycle_count;

  always @(posedge clk) begin
    if (~reset) begin
      cycle_count <= cycle_count + 1;
    end
  end

  task update_prevs();
    prev_pc = cpu_uut.core.regs.pc;
    prev_a = cpu_uut.core.regs.a;
    prev_b = cpu_uut.core.regs.b;

    prev_x = cpu_uut.core.regs.x;
    prev_y = cpu_uut.core.regs.y;

    prev_sp = cpu_uut.core.regs.sp;

    prev_carry = cpu_uut.core.regs.carry;
    prev_zero = cpu_uut.core.regs.zero;
    prev_interrupt = cpu_uut.core.regs.interrupt;
    prev_decimal = cpu_uut.core.regs.decimal;
  endtask

  task initialize_ram();
    cycle_count = 0;

    for (int i = 0; i < 256 + 256 + 128; i = i + 1) begin
      cpu_uut.ram.memory[i] = 0;
    end

    update_prevs();
  endtask

  task initialize(reg [11:0] instruction);
    bench.initialize_ram();

    #4;

    // Set instruction one 2x cycle early
    bench.rom_data = instruction;

    #2;

    bench.reset = 0;
    bench.ss_bus_reset = 0;

    // Set default values for tests
    cpu_uut.core.regs.a = 0;
    cpu_uut.core.regs.b = 1;

    cpu_uut.core.regs.x = 12'h222;
    cpu_uut.core.regs.y = 12'h333;

    cpu_uut.core.regs.sp = 8'h44;

    cpu_uut.core.regs.zero = 0;
    cpu_uut.core.regs.carry = 0;
    cpu_uut.core.regs.decimal = 0;
    cpu_uut.core.regs.interrupt = 0;

    bench.update_prevs();

    #1;
  endtask

  task run_until_final_stage_fetch();
    @(posedge clk iff cpu_uut.core.microcode.is_last_fetch_step);
  endtask

  task run_until_complete();
    @(posedge clk iff cpu_uut.core.microcode.is_last_cycle_step);
  endtask

  task run_until_halt();
    @(posedge clk iff cpu_uut.core.microcode.halt);
  endtask

  task ss_write(reg [7:0] addr, reg [31:0] data);
    bench.ss_bus_addr = addr;
    bench.ss_bus_in   = data;
    bench.ss_bus_wren = 1;

    #4;
    bench.ss_bus_addr = 0;
    bench.ss_bus_in   = 0;
    bench.ss_bus_wren = 0;
  endtask

  task assert_pc(reg [12:0] expected);
    if (expected !== 13'hXXXX) begin
      `CHECK_EQUAL(cpu_uut.core.regs.pc, expected);
    end
  endtask

  task assert_np(reg [4:0] expected);
    if (expected !== 15'hXX) begin
      `CHECK_EQUAL(cpu_uut.core.regs.np, expected);
    end
  endtask

  task assert_a(reg [3:0] expected);
    if (expected !== 4'hX) begin
      `CHECK_EQUAL(cpu_uut.core.regs.a, expected);
    end
  endtask

  task assert_b(reg [3:0] expected);
    if (expected !== 4'hX) begin
      `CHECK_EQUAL(cpu_uut.core.regs.b, expected);
    end
  endtask

  task assert_x(reg [11:0] expected);
    if (expected !== 12'hXXX) begin
      `CHECK_EQUAL(cpu_uut.core.regs.x, expected);
    end
  endtask

  task assert_y(reg [11:0] expected);
    if (expected !== 12'hXXX) begin
      `CHECK_EQUAL(cpu_uut.core.regs.y, expected);
    end
  endtask

  task assert_sp(reg [7:0] expected);
    if (expected !== 8'hXX) begin
      `CHECK_EQUAL(cpu_uut.core.regs.sp, expected);
    end
  endtask

  task assert_ram(reg [11:0] addr, reg [3:0] expected);
    if (expected !== 4'hX) begin
      `CHECK_EQUAL(cpu_uut.ram.memory[addr], expected);
    end
  endtask

  task assert_cycle_length(reg [7:0] expected);
    `CHECK_EQUAL(cycle_count - 1, expected);
  endtask

  task assert_carry(reg expected);
    `CHECK_EQUAL(cpu_uut.core.regs.carry, expected);
  endtask

  task assert_zero(reg expected);
    `CHECK_EQUAL(cpu_uut.core.regs.zero, expected);
  endtask

  task assert_interrupt(reg expected);
    `CHECK_EQUAL(cpu_uut.core.regs.interrupt, expected);
  endtask

  task assert_decimal(reg expected);
    `CHECK_EQUAL(cpu_uut.core.regs.decimal, expected);
  endtask

  task assert_ss_bus_out(reg [31:0] expected);
    `CHECK_EQUAL(ss_bus_out, expected);
  endtask

  task assert_expected(reg [12:0] expected_pc, reg [3:0] expected_a, reg [3:0] expected_b,
                       reg [11:0] expected_x, reg [11:0] expected_y, reg [7:0] expected_sp);
    assert_pc(expected_pc);
    assert_a(expected_a);
    assert_b(expected_b);

    assert_x(expected_x);
    assert_y(expected_y);

    assert_sp(expected_sp);
  endtask

  function [3:0] get_r_value(reg [1:0] r);
    case (r)
      0: get_r_value = cpu_uut.core.regs.a;
      1: get_r_value = cpu_uut.core.regs.b;
      2: get_r_value = cpu_uut.ram.memory[cpu_uut.core.regs.x];
      3: get_r_value = cpu_uut.ram.memory[cpu_uut.core.regs.y];
    endcase
  endfunction
endmodule
