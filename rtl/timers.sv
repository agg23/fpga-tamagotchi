module timers (
    input wire clk,

    input wire reset_n,

    input wire input_k03,
    input wire [2:0] prog_timer_clock_selection,
    input wire [7:0] prog_timer_reload,

    input wire reset_clock_timer,
    input wire reset_stopwatch,
    input wire reset_prog_timer,

    input wire reset_stopwatch_factor,
    input wire reset_prog_timer_factor,

    input wire enable_stopwatch,
    input wire enable_prog_timer,

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
    output wire [7:0] prog_timer_downcounter,

    output wire [1:0] stopwatch_factor,
    output wire prog_timer_factor
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

  prog_timer prog_timer (
      .clk(clk),

      .reset_n(reset_n),

      .input_k03(input_k03),

      .reset(reset_prog_timer),
      .enable(enable_prog_timer),
      .clock_selection(prog_timer_clock_selection),
      .counter_reload(prog_timer_reload),

      .reset_factor(reset_prog_timer_factor),
      .factor_flags(prog_timer_factor),

      .downcounter(prog_timer_downcounter)
  );
endmodule
