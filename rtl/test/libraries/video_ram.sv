module video_ram #(
    parameter SIM_TYPE = "modelsim"
) (
    input wire clock,

    input wire [7:0] address_a,
    input wire [3:0] data_a,
    output reg [3:0] q_a,
    input wire wren_a,

    input wire [7:0] address_b,
    input wire [3:0] data_b,
    output reg [3:0] q_b,
    input wire wren_b
);
  reg [3:0] memory[256];

  reg [7:0] stored_addr_a;
  reg [7:0] stored_addr_b;

  reg [3:0] stored_data_a;
  reg [3:0] stored_data_b;

  reg stored_wren_a;
  reg stored_wren_b;

  always @(posedge clock) begin
    stored_addr_a <= address_a;
    stored_addr_b <= address_b;

    stored_data_a <= data_a;
    stored_data_b <= data_b;

    stored_wren_a <= wren_a;
    stored_wren_b <= wren_b;

    if (stored_wren_a) begin
      memory[stored_addr_a] <= stored_data_a;
    end

    if (stored_wren_b) begin
      memory[stored_addr_b] <= stored_data_b;
    end
  end

  // TODO: Which way should this be to accurately simulate an unregistered output?
  // ModelSim and Verilator don't seem to agree
  generate
    if (SIM_TYPE == "verilator") begin
      assign q_a = memory[address_a];
      assign q_b = memory[address_b];
    end else begin
      assign q_a = memory[stored_addr_a];
      assign q_b = memory[stored_addr_b];
    end
  endgenerate
endmodule
