import ss_addresses::*;

module clock (
    input wire clk,
    input wire clk_en,

    input wire reset_n,

    input wire reset_clock_timer,

    output wire timer_128hz,
    output wire timer_64hz,
    output wire timer_32hz,
    output wire timer_16hz,
    output wire timer_8hz,
    output wire timer_4hz,
    output wire timer_2hz,
    output wire timer_1hz,

    output reg timer_256_tick = 0,

    // Savestates
    input wire [31:0] ss_bus_in,
    input wire [7:0] ss_bus_addr,
    input wire ss_bus_wren,
    input wire ss_bus_reset_n,
    output wire [31:0] ss_bus_out
);
  reg prev_reset = 0;

  reg [6:0] divider = 0;
  reg [7:0] counter_256 = 0;

  wire [31:0] ss_current_data = {16'b0, timer_256_tick, divider, counter_256};
  wire [31:0] ss_new_data;

  always @(posedge clk) begin
    if (~reset_n) begin
      prev_reset <= divider == 0;

      {timer_256_tick, divider, counter_256} <= ss_new_data[15:0];
    end else if (clk_en) begin
      prev_reset <= reset_clock_timer;

      if (reset_clock_timer) begin
        divider <= 0;
        counter_256 <= 0;

        timer_256_tick <= 0;
      end else begin
        timer_256_tick <= 0;

        divider <= divider + 7'h1;

        if (divider == 0 && ~prev_reset) begin
          // Special case to prevent ticking on reset
          counter_256 <= counter_256 + 8'h1;

          timer_256_tick <= 1;
        end
      end
    end
  end

  assign timer_128hz = counter_256[0];
  assign timer_64hz  = counter_256[1];
  assign timer_32hz  = counter_256[2];
  assign timer_16hz  = counter_256[3];
  assign timer_8hz   = counter_256[4];
  assign timer_4hz   = counter_256[5];
  assign timer_2hz   = counter_256[6];
  assign timer_1hz   = counter_256[7];

  bus_connector #(
      .ADDRESS(SS_CLOCK),
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
