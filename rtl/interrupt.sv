import ss_addresses::*;

module interrupt (
    input wire clk,
    input wire clk_en,

    input wire reset_n,

    // Clock
    input wire timer_32hz,
    input wire timer_8hz,
    input wire timer_2hz,
    input wire timer_1hz,

    // Masks
    input wire [3:0] clock_mask,
    input wire [1:0] stopwatch_mask,
    input wire prog_timer_mask,

    // Factor flags
    input wire reset_clock_factor,
    output reg [3:0] clock_factor = 0,

    input wire [1:0] stopwatch_factor,
    input wire prog_timer_factor,
    input wire [1:0] input_factor,

    // Comb
    output reg [14:0] interrupt_req = 0,

    // Savestates
    input wire [31:0] ss_bus_in,
    input wire [7:0] ss_bus_addr,
    input wire ss_bus_wren,
    input wire ss_bus_reset_n,
    output wire [31:0] ss_bus_out
);
  always_comb begin
    interrupt_req = 0;

    // Clock is 0x102 interrupt
    interrupt_req[1] = |(clock_mask & clock_factor);
    // Stopwatch is 0x104 interrupt
    interrupt_req[3] = |(stopwatch_mask & stopwatch_factor);
    // Input uses the mask for setting the factor, for some reason
    // Input K0 is 0x106 interrupt
    interrupt_req[5] = input_factor[0];
    // Input K1 is 0x108 interrupt
    interrupt_req[7] = input_factor[1];
    // Prog timer is 0x10C interrupt
    interrupt_req[11] = |(prog_timer_mask & prog_timer_factor);
  end

  reg prev_timer_32hz = 0;
  reg prev_timer_8hz = 0;
  reg prev_timer_2hz = 0;
  reg prev_timer_1hz = 0;

  wire [31:0] ss_current_data = {
    24'b0, prev_timer_32hz, prev_timer_8hz, prev_timer_2hz, prev_timer_1hz, clock_factor
  };
  wire [31:0] ss_new_data;

  always @(posedge clk) begin
    if (~reset_n) begin
      {prev_timer_32hz, prev_timer_8hz, prev_timer_2hz, prev_timer_1hz, clock_factor} <= ss_new_data[7:0];
    end else if (clk_en) begin
      prev_timer_32hz <= timer_32hz;
      prev_timer_8hz  <= timer_8hz;
      prev_timer_2hz  <= timer_2hz;
      prev_timer_1hz  <= timer_1hz;

      if (prev_timer_32hz && ~timer_32hz) begin
        clock_factor[0] <= 1;
      end

      if (prev_timer_8hz && ~timer_8hz) begin
        clock_factor[1] <= 1;
      end

      if (prev_timer_2hz && ~timer_2hz) begin
        clock_factor[2] <= 1;
      end

      if (prev_timer_1hz && ~timer_1hz) begin
        clock_factor[3] <= 1;
      end

      if (reset_clock_factor) begin
        clock_factor <= 0;
      end
    end
  end

  bus_connector #(
      .ADDRESS(SS_INTERRUPT),
      .DEFAULT_VALUE(0)
  ) ss (
      .clk(clk),

      .bus_in(ss_bus_in),
      .bus_addr(ss_bus_addr),
      .bus_wren(ss_bus_wren),
      .bus_reset_n(ss_bus_reset_n),
      .bus_out(ss_bus_out),

      .current_data(ss_current_data),
      .new_data(ss_new_data)
  );
endmodule
