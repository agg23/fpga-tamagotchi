module timers (
    input wire clk,

    input wire reset_n,

    input wire reset_clock_timer,
    input wire reset_stopwatch,

    input wire reset_stopwatch_factor,

    input wire enable_stopwatch,

    output wire timer_128hz,
    output wire timer_64hz,
    output wire timer_32hz,
    output wire timer_16hz,
    output wire timer_8hz,
    output wire timer_4hz,
    output wire timer_2hz,
    output wire timer_1hz,

    output wire [3:0] stopwatch_swl,
    output wire [3:0] stopwatch_swh,
    output wire [1:0] stopwatch_factor
);
  wire timer_256_tick;

  clock clock (
      .clk(clk),

      .reset_n(reset_n),

      .reset_clock_timer(reset_clock_timer),

      .timer_128hz(timer_128hz),
      .timer_64hz (timer_64hz),
      .timer_32hz (timer_32hz),
      .timer_16hz (timer_16hz),
      .timer_8hz  (timer_8hz),
      .timer_4hz  (timer_4hz),
      .timer_2hz  (timer_2hz),
      .timer_1hz  (timer_1hz),

      .timer_256_tick(timer_256_tick)
  );

  stopwatch stopwatch (
      .clk(clk),

      .reset_n(reset_n),

      .reset(reset_stopwatch),
      .enable(enable_stopwatch),
      .timer_256_tick(timer_256_tick),

      .reset_factor(reset_stopwatch_factor),
      .factor_flags(stopwatch_factor),

      .swl(stopwatch_swl),
      .swh(stopwatch_swh)
  );
endmodule
