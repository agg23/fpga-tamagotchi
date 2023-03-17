import ss_addresses::*;

module stopwatch (
    input wire clk,
    input wire clk_en,

    input wire reset,

    input wire mem_reset,
    input wire enable,
    input wire timer_256_tick,

    input wire reset_factor,
    output reg [1:0] factor_flags = 0,

    output wire [3:0] swl,
    output wire [3:0] swh,

    // Savestates
    input wire [31:0] ss_bus_in,
    input wire [7:0] ss_bus_addr,
    input wire ss_bus_wren,
    input wire ss_bus_reset,
    output wire [31:0] ss_bus_out
);
  reg [3:0] counter_100hz = 0;

  // Stopwatch low counter (SWL)
  reg [3:0] counter_swl = 0;

  // Stopwatch high counter (SWh)
  reg [3:0] counter_swh = 0;

  // Comb: If 0, swl will consume 2 ticks of counter_256. Otherwise, consume 3 ticks
  reg high_count_100hz = 0;

  assign swl = counter_swl;
  assign swh = counter_swh;

  wire [31:0] ss_current_data = {18'b0, factor_flags, counter_100hz, counter_swh, counter_swl};
  wire [31:0] ss_new_data;

  always_comb begin
    // If 0, count to 25. Otherwise count to 26
    reg count_26;
    // Count to 26 when 0-1, 4-5, 9-0
    count_26 = ~counter_swh[1];

    // Count to 3 on even, 2 on odd
    // EXCEPT when SWH is 1, and we're in count_26, where it's always 3
    high_count_100hz = (counter_swl == 1 && count_26) || ~counter_swl[0];
  end

  always @(posedge clk) begin
    if (reset) begin
      {factor_flags, counter_100hz, counter_swh, counter_swl} <= ss_new_data[13:0];
    end else if (clk_en) begin
      if (mem_reset) begin
        counter_100hz <= 0;
        counter_swl   <= 0;
        counter_swh   <= 0;

        factor_flags  <= 0;
      end else if (enable && timer_256_tick) begin
        // Tick 100hz
        counter_100hz <= counter_100hz + 4'h1;

        if (high_count_100hz ? counter_100hz == 2 : counter_100hz == 1) begin
          // ~100hz. Tick SWL
          counter_100hz <= 0;
          counter_swl   <= counter_swl + 4'h1;

          if (counter_swl == 9) begin
            // ~10hz. Tick SWH
            counter_swl <= 0;
            counter_swh <= counter_swh + 4'h1;
            factor_flags[0] <= 1;

            if (counter_swh == 9) begin
              // 1hz
              counter_swh <= 0;
              factor_flags[1] <= 1;
            end
          end
        end
      end

      if (reset_factor) begin
        factor_flags <= 0;
      end
    end
  end

  bus_connector #(
      .ADDRESS(SS_STOPWATCH),
      .DEFAULT_VALUE(0)
  ) ss (
      .clk(clk),

      .bus_in(ss_bus_in),
      .bus_addr(ss_bus_addr),
      .bus_wren(ss_bus_wren),
      .bus_reset(ss_bus_reset),
      .bus_out(ss_bus_out),

      .current_data(ss_current_data),
      .new_data(ss_new_data)
  );
endmodule
