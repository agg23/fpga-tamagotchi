import types::*;

module instructions_tb;

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

  task half_cycle();
    #1 clk_2x <= ~clk_2x;

    #1 clk <= ~clk;
    clk_2x <= ~clk_2x;
  endtask

  // task cycle();
  //   // #1 clk = ~clk;
  //   // #1 clk = ~clk;
  //   // #1 clk_2x = ~clk_2x;

  //   half_cycle();
  //   half_cycle();
  // endtask

  always begin
    #1 clk_2x <= ~clk_2x;

    #1 clk <= ~clk;
    clk_2x <= ~clk_2x;
  end

  // task perform_decode_fetch_instruction();
  //   // Enter with clk = 0
  //   cycle();
  //   cycle();
  //   cycle();
  // endtask

  // task finish_decode_fetch_instruction();
  //   cycle();
  // endtask

  // Values for easy reference in change detection
  reg [12:0] prev_pc;
  reg [ 3:0] prev_a;
  reg [ 3:0] prev_b;

  reg [11:0] prev_x;
  reg [11:0] prev_y;

  reg [ 7:0] prev_sp;

  task initialize_regs();
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
  endtask

  task assert_pc(reg [12:0] expected);
    assert (expected === 13'hXXXX || cpu_uut.regs.pc === expected)
    else $error("Unexpected PC: %h. Expected: %h", cpu_uut.regs.pc, expected);
  endtask

  task assert_a(reg [3:0] expected);
    assert (expected === 4'hX || cpu_uut.regs.a === expected)
    else $error("Unexpected A: %h. Expected: %h", cpu_uut.regs.a, expected);
  endtask

  task assert_b(reg [3:0] expected);
    assert (expected === 4'hX || cpu_uut.regs.b === expected)
    else $error("Unexpected B: %h. Expected: %h", cpu_uut.regs.b, expected);
  endtask

  task assert_x(reg [11:0] expected);
    assert (expected === 12'hXXX || cpu_uut.regs.x === expected)
    else $error("Unexpected X: %h. Expected: %h", cpu_uut.regs.x, expected);
  endtask

  task assert_y(reg [11:0] expected);
    assert (expected === 12'hXXX || cpu_uut.regs.y === expected)
    else $error("Unexpected Y: %h. Expected: %h", cpu_uut.regs.y, expected);
  endtask

  task assert_sp(reg [7:0] expected);
    assert (expected === 8'hXX || cpu_uut.regs.sp === expected)
    else $error("Unexpected SP: %h. Expected: %h", cpu_uut.regs.sp, expected);
  endtask

  task assert_ram(reg [11:0] addr, reg [3:0] expected);
    assert (expected === 4'hX || ram[addr] === expected)
    else $error("Unexpected RAM(%h): %h. Expected: %h", addr, ram[addr], expected);
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

  task update_prevs();
    prev_pc = cpu_uut.regs.pc;
    prev_a  = cpu_uut.regs.a;
    prev_b  = cpu_uut.regs.b;

    prev_x  = cpu_uut.regs.x;
    prev_y  = cpu_uut.regs.y;

    prev_sp = cpu_uut.regs.sp;
  endtask

  task finish_instruction();
    run_until_complete();

    update_prevs();
  endtask

  task add_instruction(reg [11:0] opcode);
    rom_data = opcode;
  endtask

  // Asserts in final fetch cycle
  task add_instruction_eval_fetch(reg [11:0] opcode, reg [12:0] expected_pc, reg [3:0] expected_a,
                                  reg [3:0] expected_b, reg [11:0] expected_x,
                                  reg [11:0] expected_y, reg [7:0] expected_sp);
    add_instruction(opcode);

    run_until_final_stage_fetch();

    // @(posedge clk);

    assert_expected(expected_pc, expected_a, expected_b, expected_x, expected_y, expected_sp);
  endtask

  // Asserts in final fetch cycle, then finishes instruction
  task add_instruction_fini_fetch(reg [11:0] opcode, reg [12:0] expected_pc, reg [3:0] expected_a,
                                  reg [3:0] expected_b, reg [11:0] expected_x,
                                  reg [11:0] expected_y, reg [7:0] expected_sp);
    add_instruction_eval_fetch(opcode, expected_pc, expected_a, expected_b, expected_x, expected_y,
                               expected_sp);

    finish_instruction();
  endtask

  task run_until_final_stage_fetch();
    // while (~cpu_uut.microcode.last_fetch_step) begin
    //   half_cycle();
    // end

    // half_cycle();

    // @(posedge clk);

    @(posedge clk iff cpu_uut.microcode.last_fetch_step);
  endtask

  task run_until_complete();
    while (~cpu_uut.microcode.last_cycle_step) begin
      half_cycle();
    end

    half_cycle();

    // @(posedge clk iff cpu_uut.microcode.stage == cpu_uut.microcode.DECODE);

    // @(posedge clk);
  endtask

  initial begin
    initialize_regs();

    // half_cycle();

    // cycle();
    // cycle();

    reset_n = 1;
    // perform_decode_fetch_instruction();
    // run_until_final_stage_fetch();
    // run_until_complete();
    // cycle();

    // We run a whole instruction just to make sure the timing all lines up
    update_prevs();

    //                         [opcode] [   pc  ] [  a  ] [  b  ] [  x  ] [  y  ] [  sp  ]
    // -----------------------------------------------------------------------------------

    // JP 0x23
    // add_instruction_fini_fetch(12'h023, 13'h0123, prev_a, prev_b, prev_x, prev_y, prev_sp);
    // add_instruction(12'h023);

    // run_until_final_stage_fetch();

    // $display(clk);

    // @(posedge clk);

    // assert_expected(13'h0123, prev_a, prev_b, prev_x, prev_y, prev_sp);

    // finish_instruction();


    // JP 0x45 and set PCB + PCP from NBP + NPP
    // cpu_uut.regs.np = 5'h12;
    // add_instruction_fini_fetch(12'h045, 13'h1245, prev_a, prev_b, prev_x, prev_y, prev_sp);

    // // RETD 0xFC
    cpu_uut.regs.x = 12'h4F1;
    cpu_uut.regs.sp = 8'h44;
    ram[8'h44] = 4'hD;  // PCSL
    ram[8'h45] = 4'h4;  // PCSL
    ram[8'h46] = 4'h7;  // PCP

    add_instruction_fini_fetch(12'h1FC, 13'h174D, prev_a, prev_b, 12'hXXX, prev_y, 8'h47);

    $display("%h, %h", clk, cpu_uut.regs.x);

    // wait(posedge clk);

    $display("%h, %h", clk, cpu_uut.regs.x);

    // Assert final values from RETD 0xFC, should have updated X and written to mem
    assert_ram(12'h4F0, 4'hC);  // Lower nibble of immediate
    assert_ram(12'h4F2, 4'hF);  // Upper nibble of immediate

    assert_x(12'h4F3);


    // // JP C, 0x2D. Should not jump since carry isn't set
    // add_instruction(12'h2CD);

    // half_cycle();
    // update_prevs();

    // // Assert final values from RETD 0xFC, should have updated X and written to mem
    // assert_ram(12'h4F1, 4'hC);  // Lower nibble of immediate
    // assert_ram(12'h4F2, 4'hF);  // Upper nibble of immediate

    // assert_x(12'h4F3);

    // // Finished JP C, 0x2D
    // add_instruction_eval_fetch(12'h2CD, prev_pc, prev_a, prev_b, prev_x, prev_y, prev_sp);
  end
endmodule
