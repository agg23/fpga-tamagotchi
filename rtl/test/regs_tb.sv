import types::*;

module regs_tb;
  reg clk = 0;
  microcode_cycle cycle;

  reg_type bus_input_selector;
  reg_type bus_output_selector;
  reg_inc_type increment_selector;

  reg [3:0] alu_out = 0;
  reg alu_zero = 0;
  reg alu_carry = 0;
  reg [7:0] immed_out = 0;

  wire memory_write_en;
  wire [11:0] memory_addr;
  wire [3:0] memory_write_data;
  reg [3:0] memory_read_data;

  regs regs_uut (
      .clk(clk),
      .current_cycle(cycle),

      .bus_input_selector (bus_input_selector),
      .bus_output_selector(bus_output_selector),
      .increment_selector (increment_selector),

      .alu(alu_out),
      .alu_zero(alu_zero),
      .alu_carry(alu_carry),
      .immed(immed_out),

      .memory_write_en(memory_write_en),
      .memory_addr(memory_addr),
      .memory_write_data(memory_write_data),
      .memory_read_data(memory_read_data)
  );

  reg begin_cycle = 0;

  always @(posedge clk) begin
    if (cycle != CYCLE_NONE) begin
      case (cycle)
        CYCLE_REG_FETCH: cycle <= CYCLE_REG_WRITE;
        CYCLE_REG_WRITE: cycle <= CYCLE_NONE;
      endcase
    end else if (begin_cycle) begin
      cycle <= CYCLE_REG_FETCH;
    end
  end

  reg [11:0] last_read_memory_addr = 0;
  reg [3:0] future_memory_read_data;
  reg awaiting_read_data = 0;

  always @(posedge clk) begin
    if (memory_addr != last_read_memory_addr) begin
      last_read_memory_addr <= memory_addr;
      awaiting_read_data <= 1;
    end

    if (awaiting_read_data) begin
      memory_read_data <= future_memory_read_data;
    end
  end

  reg [3:0] written_memory_data;

  always @(posedge clk) begin
    if (memory_write_en) begin
      written_memory_data <= memory_write_data;
    end
  end

  task clk_cycle();
    #1 clk = ~clk;
    #1 clk = ~clk;
  endtask

  task perform_microinstruction();
    if (clk) begin
      #1 clk = ~clk;
    end

    // Enter with clk = 0
    begin_cycle = 1;

    clk_cycle();

    begin_cycle = 0;
    clk_cycle();

    clk_cycle();
  endtask

  task ld_immed_low(reg_type destination, reg [3:0] immed);
    immed_out[3:0] = immed;
    bus_input_selector = REG_IMML;
    bus_output_selector = destination;

    perform_microinstruction();
  endtask

  task ld_immed_high(reg_type destination, reg [3:0] immed);
    immed_out[7:4] = immed;
    bus_input_selector = REG_IMMH;
    bus_output_selector = destination;

    perform_microinstruction();
  endtask

  task transfer(reg_type source, reg_type destination);
    bus_input_selector  = source;
    bus_output_selector = destination;

    perform_microinstruction();
  endtask

  task assert_ld_immed_low(reg_type destination, reg [3:0] immed);
    ld_immed_low(destination, immed);

    assert_reg_value(destination, immed);
  endtask

  function [3:0] reg_value(reg_type destination);
    reg_value = 0;

    case (destination)
      REG_A: reg_value = regs_uut.a;
      REG_B: reg_value = regs_uut.b;
      REG_TEMPA: reg_value = regs_uut.temp_a;
      REG_TEMPB: reg_value = regs_uut.temp_b;

      REG_XL: reg_value = regs_uut.x[3:0];
      REG_XH: reg_value = regs_uut.x[7:4];
      REG_XP: reg_value = regs_uut.x[11:8];

      REG_YL: reg_value = regs_uut.y[3:0];
      REG_YH: reg_value = regs_uut.y[7:4];
      REG_YP: reg_value = regs_uut.y[11:8];

      REG_SPL: reg_value = regs_uut.sp[3:0];
      REG_SPH: reg_value = regs_uut.sp[7:4];
    endcase
  endfunction

  function assert_reg_value(reg_type destination, reg [3:0] value);
    assert (reg_value(destination) == value)
    else $error("%s was not set to %d", destination, value);
  endfunction

  function assert_mem_addr(reg [11:0] expected);
    assert (memory_addr == expected)
    else $error("Unexpected memory address: %h. Expected: %h", memory_addr, expected);
  endfunction

  function assert_written_mem_data(reg [3:0] expected);
    assert (written_memory_data == expected)
    else $error("Incorrect written data: %h. Expected: %h", written_memory_data, expected);
  endfunction

  function assert_carry(reg expected);
    assert (regs_uut.carry == expected)
    else $error("Carry was not set to %d", expected);
  endfunction

  function assert_zero(reg expected);
    assert (regs_uut.zero == expected)
    else $error("Zero was not set to %d", expected);
  endfunction

  function assert_decimal(reg expected);
    assert (regs_uut.decimal == expected)
    else $error("Decimal was not set to %d", expected);
  endfunction

  function assert_interrupt(reg expected);
    assert (regs_uut.interrupt == expected)
    else $error("Interrupt was not set to %d", expected);
  endfunction

  initial begin
    cycle = CYCLE_NONE;
    bus_input_selector = REG_ALU;
    bus_output_selector = REG_ALU;
    increment_selector = REG_NONE;

    #1 clk = ~clk;
    #1 clk = ~clk;

    perform_microinstruction();

    // Load 0xF into A
    assert_ld_immed_low(REG_A, 4'hF);

    // Load 0xA into B
    ld_immed_high(REG_B, 4'hA);

    transfer(REG_A, REG_TEMPB);
    assert_reg_value(REG_TEMPB, 4'hF);

    transfer(REG_B, REG_TEMPA);
    assert_reg_value(REG_TEMPA, 4'hA);

    // Load 0x345 into X
    assert_ld_immed_low(REG_XL, 4'h5);
    assert_ld_immed_low(REG_XH, 4'h4);
    assert_ld_immed_low(REG_XP, 4'h3);

    assert (regs_uut.x == 12'h345)
    else $error("X was not set to 0x345");

    // Load 0xFED into Y
    assert_ld_immed_low(REG_TEMPA, 4'hF);
    assert_ld_immed_low(REG_TEMPB, 4'hE);
    transfer(REG_TEMPA, REG_YP);
    transfer(REG_TEMPB, REG_YH);
    assert_ld_immed_low(REG_A, 4'hD);
    transfer(REG_A, REG_YL);

    assert (regs_uut.y == 12'hFED)
    else $error("Y was not set to 0xFED");

    // Load 0xF7 into SP
    alu_out = 4'h7;
    transfer(REG_ALU, REG_SPL);
    transfer(REG_TEMPA, REG_SPH);

    assert (regs_uut.sp == 8'hF7)
    else $error("SP was not set to 0xF7");

    // Hardcoded 1
    transfer(REG_HARDCODED_1, REG_A);

    assert_reg_value(REG_A, 4'h1);

    // Transfer immediate addressed reg A to B
    immed_out = 8'b0000_01_00;
    transfer(REG_IMM_ADDR_L, REG_IMM_ADDR_H);

    assert_reg_value(REG_A, 4'h1);
    assert_reg_value(REG_B, 4'h1);

    // Transfer immediate addressed MY to A
    future_memory_read_data = 4'h4;
    immed_out = 8'b0100_11_10;
    transfer(REG_IMM_ADDR_H, REG_IMM_ADDR_P);

    assert_reg_value(REG_A, 4'h4);
    assert_reg_value(REG_B, 4'h1);

    // Memory Reads
    // ------------
    // Load 0x1 from MX
    future_memory_read_data = 4'h1;
    transfer(REG_MX, REG_A);

    assert_reg_value(REG_A, 4'h1);
    assert_mem_addr(12'h345);

    // Load 0xC from MY
    future_memory_read_data = 4'hC;
    transfer(REG_MY, REG_B);

    assert_reg_value(REG_B, 4'hC);
    assert_mem_addr(12'hFED);

    // Load 0x4 from M(7)
    future_memory_read_data = 4'h4;
    immed_out = 4'h7;
    transfer(REG_Mn, REG_TEMPA);

    assert_reg_value(REG_TEMPA, 4'h4);
    assert_mem_addr(12'h7);

    // Load 0xF from MSP
    future_memory_read_data = 4'hF;
    transfer(REG_MSP, REG_TEMPB);

    assert_reg_value(REG_TEMPB, 4'hF);
    assert_mem_addr(12'hF7);

    // Memory Writes
    // -------------
    // Write 0xF to MX
    transfer(REG_TEMPB, REG_MX);

    assert_written_mem_data(4'hF);
    assert_mem_addr(12'h345);

    // Write 0xC to MSP
    transfer(REG_B, REG_MSP);

    assert_written_mem_data(4'hC);
    assert_mem_addr(12'hF7);

    // Post-increment
    // --------------
    // Write 0x4 to MX and post-increment X
    increment_selector = REG_XHL;
    transfer(REG_TEMPA, REG_MX);

    assert_written_mem_data(4'h4);
    assert_mem_addr(12'h345);

    assert (regs_uut.x == 12'h346)
    else $error("X was not set to 0x346");

    // Test Y post-increment wrapping
    increment_selector = REG_NONE;
    assert_ld_immed_low(REG_YL, 4'hF);
    assert_ld_immed_low(REG_YH, 4'hF);
    assert_ld_immed_low(REG_YP, 4'h2);

    increment_selector = REG_YHL;
    // Write 0xF to MX and post-increment Y
    transfer(REG_YL, REG_MY);

    assert_written_mem_data(4'hF);
    assert_mem_addr(12'h2FF);

    assert (regs_uut.y == 12'h200)
    else $error("Y was not set to 0x200");

    // Copy SPL (0x7) and post-increment SP
    increment_selector = REG_SP_INC;
    transfer(REG_SPL, REG_A);

    assert_reg_value(REG_A, 4'h7);
    assert (regs_uut.sp == 8'hF8)
    else $error("SP was not set to 0xF8");

    // Pre-increment
    // -------------
    // Write SPL (0x8) to M(SP - 1)
    increment_selector = REG_SP_DEC;
    transfer(REG_SPL, REG_MSP_DEC);

    assert_written_mem_data(4'h8);
    assert_mem_addr(8'hF7);
    assert (regs_uut.sp == 8'hF7)
    else $error("SP was not set to 0xF7");

    increment_selector = REG_NONE;

    // Flags
    // -----
    // Set all flags
    ld_immed_low(REG_FLAGS, 4'hF);

    assert_carry(1);
    assert_zero(1);
    assert_decimal(1);
    assert_interrupt(1);

    // AND flags with 0x5
    transfer(REG_FLAGS, REG_TEMPA);

    assert_reg_value(REG_TEMPA, 4'hF);
    alu_out = 4'h5;  // 0xF & 0x5
    transfer(REG_ALU, REG_FLAGS);

    assert_carry(1);
    assert_zero(0);
    assert_decimal(1);
    assert_interrupt(0);

    // REG_ALU_WITH_FLAGS should copy ALU flags
    alu_out   = 4'h8;
    alu_zero  = 1;
    alu_carry = 0;
    transfer(REG_ALU_WITH_FLAGS, REG_A);

    assert_reg_value(REG_A, 4'h8);
    assert_carry(0);
    assert_zero(1);
    assert_decimal(1);
    assert_interrupt(0);

    // REG_ALU should not copy flags
    alu_out   = 4'hF;
    alu_zero  = 1;
    alu_carry = 1;
    transfer(REG_ALU, REG_B);

    assert_reg_value(REG_B, 4'hF);
    assert_carry(0);
    assert_zero(1);
    assert_decimal(1);
    assert_interrupt(0);
  end
endmodule
