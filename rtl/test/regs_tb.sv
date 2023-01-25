import types::*;

module regs_tb;
  reg clk = 0;
  microcode_cycle cycle;

  reg_type bus_input_selector;
  reg_type bus_output_selector;

  reg [3:0] alu_out = 0;
  reg [3:0] immed_out = 0;

  wire [11:0] memory_addr;
  reg [3:0] memory_data;

  regs regs_uut (
      .clk(clk),
      .current_cycle(cycle),

      .bus_input_selector (bus_input_selector),
      .bus_output_selector(bus_output_selector),

      .alu  (alu_out),
      .immed(immed_out),

      .memory_addr(memory_addr),
      .memory_data(memory_data)
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

  task perform_microinstruction();
    if (clk) begin
      #1 clk = ~clk;
    end

    // Enter with clk = 0
    begin_cycle = 1;

    #1 clk = ~clk;
    #1 clk = ~clk;

    begin_cycle = 0;
    #1 clk = ~clk;
    #1 clk = ~clk;

    #1 clk = ~clk;
    #1 clk = ~clk;
  endtask

  task ld_immed(reg_type destination, reg [3:0] immed);
    immed_out = immed;
    bus_input_selector = REG_IMM;
    bus_output_selector = destination;

    perform_microinstruction();
  endtask

  task transfer(reg_type source, reg_type destination);
    bus_input_selector  = source;
    bus_output_selector = destination;

    perform_microinstruction();
  endtask

  task assert_ld_immed(reg_type destination, reg [3:0] immed);
    ld_immed(destination, immed);

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

  initial begin
    cycle = CYCLE_NONE;
    bus_input_selector = REG_ALU;
    bus_output_selector = REG_ALU;

    #1 clk = ~clk;
    #1 clk = ~clk;

    perform_microinstruction();

    // Load 0xF into A
    assert_ld_immed(REG_A, 4'hF);

    // Load 0xA into B
    assert_ld_immed(REG_B, 4'hA);

    transfer(REG_A, REG_TEMPB);
    assert_reg_value(REG_TEMPB, 4'hF);

    transfer(REG_B, REG_TEMPA);
    assert_reg_value(REG_TEMPA, 4'hA);

    // Load 0x345 into X
    assert_ld_immed(REG_XL, 4'h5);
    assert_ld_immed(REG_XH, 4'h4);
    assert_ld_immed(REG_XP, 4'h3);

    assert (regs_uut.x == 12'h345)
    else $error("X was not set to 0x345");

    // Load 0xFED into Y
    assert_ld_immed(REG_TEMPA, 4'hF);
    assert_ld_immed(REG_TEMPB, 4'hE);
    transfer(REG_TEMPA, REG_YP);
    transfer(REG_TEMPB, REG_YH);
    assert_ld_immed(REG_A, 4'hD);
    transfer(REG_A, REG_YL);

    assert (regs_uut.y == 12'hFED)
    else $error("Y was not set to 0xFED");

    // Load 0xFD into SP
    transfer(REG_A, REG_SPL);
    transfer(REG_TEMPA, REG_SPH);

    assert (regs_uut.sp == 8'hFD)
    else $error("SP was not set to 0xFD");

    // TODO: Test memory
  end
endmodule
