module cpu_6s46 (
    input wire clk,
    input wire clk_2x,

    output wire [12:0] rom_addr,
    input  wire [11:0] rom_data
);
  wire memory_write_en;
  wire [11:0] memory_addr;
  wire [3:0] memory_write_data;
  reg [3:0] memory_read_data;

  // RAM from 0x000 - 0x280
  reg [3:0] ram[256+256+128];

  cpu core (
      .clk(clk),
      .clk_2x(clk_2x),

      .rom_addr(rom_addr),
      .rom_data(rom_data),

      .memory_write_en(memory_write_en),
      .memory_addr(memory_addr),
      .memory_write_data(memory_write_data),
      .memory_read_data(memory_read_data),

      // TODO
      .interrupt_req(0)
  );

  // RAM bus
  always @(posedge clk) begin
    if (memory_addr < 12'h280) begin
      // Actual RAM space
      if (memory_write_en) begin
        ram[memory_addr[9:0]] <= memory_write_data;
      end else begin
        memory_read_data <= ram[memory_addr[9:0]];
      end
    end else if (memory_addr >= 12'hE00 && memory_addr < 12'hE50) begin
      // Display lower segment
    end else if (memory_addr >= 12'hE80 && memory_addr < 12'hED0) begin
      // Display upper segment
    end else if (memory_addr[11:8] == 4'hF) begin
      // I/O segment
    end
  end

endmodule
