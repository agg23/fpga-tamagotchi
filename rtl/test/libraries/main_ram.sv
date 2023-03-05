module main_ram (
    input wire clock,

    input wire [9:0] address,
    input wire [3:0] data,
    output wire [3:0] q,
    input wire wren
);
  reg [3:0] memory[1024];

  always @(posedge clock) begin
    if (wren) begin
      memory[address] <= data;
    end
  end

  assign q = memory[address];
endmodule
