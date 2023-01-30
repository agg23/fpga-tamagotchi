import types::*;

module cpu_tb;

  reg clk = 0;
  reg clk_2x = 1;

  reg reset_n = 0;

  cpu cpu_uut (
      .clk(clk),
      .clk_2x(clk_2x),

      .reset_n(reset_n)
  );

  task cycle();
    // #1 clk = ~clk;
    // #1 clk = ~clk;
    // #1 clk_2x = ~clk_2x;

    #1 clk_2x = ~clk_2x;

    #1 clk = ~clk;
    clk_2x = ~clk_2x;

    #1 clk_2x = ~clk_2x;

    #1 clk = ~clk;
    clk_2x = ~clk_2x;
  endtask

  initial begin
    cpu_uut.regs.a = 4'h5;

    cycle();
    cycle();

    reset_n = 1;
    forever begin
      cycle();
    end
  end
endmodule
