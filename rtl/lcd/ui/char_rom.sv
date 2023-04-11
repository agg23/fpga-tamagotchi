module char_rom (
    input wire clk,

    input  wire [6:0] character,
    input  wire [2:0] row,
    output reg  [7:0] data_out
);
  reg [7:0] rom[2 ** 10 - 1:0];

  initial $readmemh("../assets/PixelOperatorMono.hex", rom);

  // Data loading
  always @(posedge clk) begin
    data_out <= rom[character*8+row];
  end
endmodule
