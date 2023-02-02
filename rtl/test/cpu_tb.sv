import types::*;

module cpu_tb;

  reg clk = 0;
  reg clk_2x = 1;

  reg reset_n = 0;

  wire [12:0] rom_addr;
  reg [11:0] rom_data;

  reg [11:0] rom[8192];

  initial $readmemh("C:/Users/adam/code/fpga/tamagotchi/bass/simple_add.hex", rom);

  cpu cpu_uut (
      .clk(clk),
      .clk_2x(clk_2x),

      .reset_n(reset_n),

      .rom_addr(rom_addr),
      .rom_data(rom_data)
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

  always @(posedge clk) begin
    // ROM access
    rom_data <= rom[rom_addr];
  end

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
