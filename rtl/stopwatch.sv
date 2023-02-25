module stopwatch (
    input wire clk,

    input wire reset_n,

    input wire reset,
    input wire enable,
    input wire timer_256_tick,

    input wire reset_factor,
    output reg [1:0] factor_flags = 0,

    output wire [3:0] swl,
    output wire [3:0] swh
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
    if (~reset_n || reset) begin
      counter_100hz <= 0;
      counter_swl   <= 0;
      counter_swh   <= 0;

      factor_flags  <= 0;
    end else begin
      if (enable && timer_256_tick) begin
        // Tick 100hz
        counter_100hz <= counter_100hz + 1;

        if (high_count_100hz ? counter_100hz == 2 : counter_100hz == 1) begin
          // ~100hz. Tick SWL
          counter_100hz <= 0;
          counter_swl   <= counter_swl + 1;

          if (counter_swl == 9) begin
            // ~10hz. Tick SWH
            counter_swl <= 0;
            counter_swh <= counter_swh + 1;
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

endmodule
