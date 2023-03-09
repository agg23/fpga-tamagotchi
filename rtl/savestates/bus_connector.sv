import ss_addresses::*;

module bus_connector #(
    parameter [ SS_BUS_WIDTH-1:0] ADDRESS,
    parameter [SS_DATA_WIDTH-1:0] DEFAULT_VALUE = 0
) (
    input wire clk,

    /// The data coming in over the data bus
    input wire [SS_DATA_WIDTH-1:0] bus_in,
    /// The address of the data on the bus
    input wire [SS_BUS_WIDTH-1:0] bus_addr,
    /// If set, write this data
    input wire bus_wren,
    /// If set, restore the default value to this register selection
    input wire bus_reset_n,
    /// The data being output at this bus address
    output reg [SS_DATA_WIDTH-1:0] bus_out,

    /// The data currently stored by the core
    input  wire [SS_DATA_WIDTH-1:0] current_data,
    /// The data to reset to via the SS system
    output wire [SS_DATA_WIDTH-1:0] new_data
);
  /// Only stores the data coming in over bus
  reg [SS_DATA_WIDTH-1:0] buffer = 0;

  assign new_data = buffer;

  wire matching_address = bus_addr == ADDRESS;

  always_comb begin
    bus_out = 0;

    if (matching_address) begin
      bus_out = current_data;
    end
  end

  always @(posedge clk) begin
    if (~bus_reset_n) begin
      buffer <= DEFAULT_VALUE;
    end else if (bus_wren && matching_address) begin
      buffer <= bus_in;
    end
  end

endmodule
