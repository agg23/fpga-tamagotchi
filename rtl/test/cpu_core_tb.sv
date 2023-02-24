import types::*;

module cpu_core_tb;

  reg clk = 0;
  reg clk_2x = 1;

  reg reset_n = 0;

  wire [12:0] rom_addr;
  reg [11:0] rom_data;

  wire memory_write_en;
  wire [11:0] memory_addr;
  wire [3:0] memory_write_data;
  reg [3:0] memory_read_data;

  reg [11:0] rom[8192];

  initial $readmemh("C:/Users/adam/code/fpga/tamagotchi/bass/fib_optimized.hex", rom);

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

  always @(posedge clk) begin
    // RAM access
    if (memory_write_en) begin
      ram[memory_addr] <= memory_write_data;
    end else begin
      memory_read_data <= ram[memory_addr];
    end
  end

  initial begin
    cycle();
    cycle();

    reset_n = 1;
    forever begin
      cycle();
    end
  end
endmodule
