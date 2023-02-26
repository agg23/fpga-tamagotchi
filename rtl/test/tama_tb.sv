module tama_tb;

  reg clk = 0;
  reg clk_2x = 1;

  reg reset_n = 0;

  wire [12:0] rom_addr;
  reg [11:0] rom_data;

  // ROM is 16 bit
  reg [15:0] rom[8192];

  initial $readmemh("C:/Users/adam/code/fpga/tamagotchi/bass/tama.hex", rom);

  cpu_6s46 cpu_uut (
      .clk(clk),
      .clk_2x(clk_2x),

      .reset_n(reset_n),

      .input_k0(4'hE),
      .input_k1(4'h0),

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
    rom_data <= rom[rom_addr][11:0];
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
