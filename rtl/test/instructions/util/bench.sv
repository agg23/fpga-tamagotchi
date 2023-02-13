`include "vunit_defines.svh"

module bench;
  reg clk = 0;
  reg clk_2x = 1;

  reg reset_n = 0;

  wire [12:0] rom_addr;
  reg [11:0] rom_data = 0;

  wire memory_write_en;
  wire [11:0] memory_addr;
  wire [3:0] memory_write_data;
  reg [3:0] memory_read_data = 0;

  reg [3:0] ram[4096];

  cpu cpu_uut (
      .clk(clk),
      .clk_2x(clk_2x),

      .reset_n(reset_n),

      .rom_addr(rom_addr),
      .rom_data(rom_data),

      .memory_write_en(memory_write_en),
      .memory_addr(memory_addr),
      .memory_write_data(memory_write_data),
      .memory_read_data(memory_read_data)
  );

  always @(posedge clk) begin
    // RAM access
    if (memory_write_en) begin
      ram[memory_addr] <= memory_write_data;
    end else begin
      memory_read_data <= ram[memory_addr];
    end
  end

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
  reg [ 3:0] prev_a;
  reg [ 3:0] prev_b;

  reg [11:0] prev_x;
  reg [11:0] prev_y;

  reg [ 7:0] prev_sp;

  reg [ 7:0] cycle_count;

  always @(posedge clk) begin
    if (bench.reset_n) begin
      cycle_count <= cycle_count + 1;
    end
  end

  task update_prevs();
    prev_pc = cpu_uut.regs.pc;
    prev_a  = cpu_uut.regs.a;
    prev_b  = cpu_uut.regs.b;

    prev_x  = cpu_uut.regs.x;
    prev_y  = cpu_uut.regs.y;

    prev_sp = cpu_uut.regs.sp;
  endtask

  task initialize_regs();
    cycle_count = 0;

    cpu_uut.regs.a = 0;
    cpu_uut.regs.b = 1;

    cpu_uut.regs.x = 12'h222;
    cpu_uut.regs.y = 12'h333;

    cpu_uut.regs.sp = 8'h44;

    cpu_uut.regs.zero = 0;
    cpu_uut.regs.carry = 0;
    cpu_uut.regs.decimal = 0;
    cpu_uut.regs.interrupt = 0;

    for (int i = 0; i < 4096; i = i + 1) begin
      ram[i] = 0;
    end

    update_prevs();
  endtask

  task initialize();
    bench.initialize_regs();

    #2;

    bench.reset_n = 1;
  endtask

  task run_until_final_stage_fetch();
    @(posedge clk iff cpu_uut.microcode.last_fetch_step);
  endtask

  task run_until_complete();
    @(posedge clk iff cpu_uut.microcode.last_cycle_step);
  endtask

  task assert_pc(reg [12:0] expected);
    if (expected !== 13'hXXXX) begin
      `CHECK_EQUAL(cpu_uut.regs.pc, expected);
    end
  endtask

  task assert_a(reg [3:0] expected);
    if (expected !== 4'hX) begin
      `CHECK_EQUAL(cpu_uut.regs.a, expected);
    end
  endtask

  task assert_b(reg [3:0] expected);
    if (expected !== 4'hX) begin
      `CHECK_EQUAL(cpu_uut.regs.b, expected);
    end
  endtask

  task assert_x(reg [11:0] expected);
    if (expected !== 12'hXXX) begin
      `CHECK_EQUAL(cpu_uut.regs.x, expected);
    end
  endtask

  task assert_y(reg [11:0] expected);
    if (expected !== 12'hXXX) begin
      `CHECK_EQUAL(cpu_uut.regs.y, expected);
    end
  endtask

  task assert_sp(reg [7:0] expected);
    if (expected !== 8'hXX) begin
      `CHECK_EQUAL(cpu_uut.regs.sp, expected);
    end
  endtask

  task assert_ram(reg [11:0] addr, reg [3:0] expected);
    if (expected !== 4'hX) begin
      `CHECK_EQUAL(ram[addr], expected);
    end
  endtask

  task assert_cycle_length(reg [3:0] expected);
    `CHECK_EQUAL(cycle_count - 1, expected);
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
endmodule
