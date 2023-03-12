module main_ram (
    input wire clock,

    input wire [9:0] address,
    input wire [3:0] data,
    output wire [3:0] q,
    input wire wren
);
  reg [3:0] memory[1024];

  reg [9:0] stored_addr;
  reg [3:0] stored_data;
  reg stored_wren;

  always @(posedge clock) begin
    stored_addr <= address;
    stored_data <= data;
    stored_wren <= wren;

    if (stored_wren) begin
      memory[stored_addr] <= stored_data;
    end
  end

  assign q = memory[stored_addr];
endmodule
