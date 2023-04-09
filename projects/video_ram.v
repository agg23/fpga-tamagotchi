// Proxy module to allow Verilator to have a custom implementation, but ignored
// by ModelSim and Quartus
module video_ram #(
    parameter SIM_TYPE = "modelsim"
) (
    input [7:0] address_a,
    input [7:0] address_b,
    input clock,
    input [3:0] data_a,
    input [3:0] data_b,
    input wren_a,
    input wren_b,
    output [3:0] q_a,
    output [3:0] q_b
);
  intel_video_ram video_ram (
      .clock(clock),

      .address_a(address_a),
      .data_a(data_a),
      .q_a(q_a),
      .wren_a(wren_a),

      .address_b(address_b),
      .data_b(data_b),
      .q_b(q_b),
      .wren_b(wren_b)
  );
endmodule
