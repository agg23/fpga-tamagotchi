// Clones video_ram on vsync so we have a stable "frame" of the LCD
module frame_ram (
    input wire clk,

    input  wire [7:0] frame_addr,
    output reg  [3:0] frame_data = 0,

    output reg [7:0] sprite_enable_status = 0,

    output reg  [7:0] cpu_video_addr = 0,
    input  wire [3:0] cpu_video_data,

    input wire vsync
);
  reg [3:0] memory[256];

  reg init_read_delay = 0;

  always @(posedge clk) begin
    reg [7:0] write_addr;

    cpu_video_addr  <= 0;
    init_read_delay <= 0;

    if (vsync) begin
      memory[cpu_video_addr] <= cpu_video_data;

      cpu_video_addr <= 8'h1;
      init_read_delay <= 1;
    end else if (init_read_delay) begin
      // End of this cycle, data for 0x1 will be available, so start 0x2
      cpu_video_addr <= 8'h2;
    end else if (cpu_video_addr != 0) begin
      // Write byte
      write_addr = cpu_video_addr - 8'h1;

      memory[write_addr] <= cpu_video_data;

      // Will automatically stop copying on overflow
      cpu_video_addr <= cpu_video_addr + 8'h1;

      // Extract sprite data while fetching
      if (write_addr == 8'h10) begin
        // Upper sprite status data
        // {1'b0, 6'd8, 1'b0}
        sprite_enable_status[3:0] <= cpu_video_data;
      end else if (write_addr == 8'h89) begin
        // Lower sprite status data
        // Second RAM bank, y = 12
        // {1'b0, 6'd28, 1'b1} + 8'h50
        sprite_enable_status[7:4] <= cpu_video_data;
      end
    end else begin
      frame_data <= memory[frame_addr];
    end
  end
endmodule
