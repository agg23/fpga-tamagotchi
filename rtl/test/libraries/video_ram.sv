module video_ram (
    input wire clock,

    input wire [7:0] address_a,
    input wire [3:0] data_a,
    output wire [3:0] q_a,
    input wire wren_a,

    input wire [7:0] address_b,
    input wire [3:0] data_b,
    output wire [3:0] q_b,
    input wire wren_b
);
  reg [3:0] memory[256];

  always @(posedge clock) begin
    if (wren_a) begin
      memory[address_a] <= data_a;
    end

    if (wren_b) begin
      memory[address_b] <= data_b;
    end
  end

  assign q_a = memory[address_a];
  assign q_b = memory[address_b];
endmodule
