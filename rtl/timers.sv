module timers (
    input wire clk,

    input wire reset_n,

    input wire reset_clock_timer,

    output wire timer_128hz,
    output wire timer_64hz,
    output wire timer_32hz,
    output wire timer_16hz,
    output wire timer_8hz,
    output wire timer_4hz,
    output wire timer_2hz,
    output wire timer_1hz
);
  wire [7:0] counter_256;

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

      .counter_256(counter_256)
  );

  stopwatch stopwatch (
      .clk(clk),

      .reset_n(reset_n),

      .counter_256(counter_256)
  );


endmodule
