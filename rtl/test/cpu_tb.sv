import types::*;

module cpu_tb;

  reg clk = 0;

  cpu cpu_uut (.clk(clk));

  task cycle();
    #1 clk = ~clk;
    #1 clk = ~clk;
  endtask

  initial begin
    cpu_uut.regs.a = 4'h5;

    cycle();
    cycle();
    cycle();
    cycle();
    cycle();
    cycle();
    cycle();
    cycle();
  end
endmodule
