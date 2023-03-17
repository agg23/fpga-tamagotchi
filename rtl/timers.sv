module timers (
    input wire clk,
    input wire clk_en,

    input wire reset,

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
    output wire prog_timer_factor,

    // Savestates
    input wire [31:0] ss_bus_in,
    input wire [7:0] ss_bus_addr,
    input wire ss_bus_wren,
    input wire ss_bus_reset,
    output wire [31:0] ss_bus_out
);
  wire timer_256_tick;

  wire [31:0] ss_bus_out_clock;
  wire [31:0] ss_bus_out_stopwatch;
  wire [31:0] ss_bus_out_prog_timer;

  assign ss_bus_out = ss_bus_out_clock | ss_bus_out_stopwatch | ss_bus_out_prog_timer;

  clock clock (
      .clk(clk),
      .clk_en(clk_en),

      .reset(reset),

      .reset_clock_timer(reset_clock_timer),

      .timer_128hz(timer_128hz),
      .timer_64hz (timer_64hz),
      .timer_32hz (timer_32hz),
      .timer_16hz (timer_16hz),
      .timer_8hz  (timer_8hz),
      .timer_4hz  (timer_4hz),
      .timer_2hz  (timer_2hz),
      .timer_1hz  (timer_1hz),

      .timer_256_tick(timer_256_tick),

      // Savestates
      .ss_bus_in(ss_bus_in),
      .ss_bus_addr(ss_bus_addr),
      .ss_bus_wren(ss_bus_wren),
      .ss_bus_reset(ss_bus_reset),
      .ss_bus_out(ss_bus_out_clock)
  );

  stopwatch stopwatch (
      .clk(clk),
      .clk_en(clk_en),

      .reset(reset),

      .mem_reset(reset_stopwatch),
      .enable(enable_stopwatch),
      .timer_256_tick(timer_256_tick),

      .reset_factor(reset_stopwatch_factor),
      .factor_flags(stopwatch_factor),

      .swl(stopwatch_swl),
      .swh(stopwatch_swh),

      // Savestates
      .ss_bus_in(ss_bus_in),
      .ss_bus_addr(ss_bus_addr),
      .ss_bus_wren(ss_bus_wren),
      .ss_bus_reset(ss_bus_reset),
      .ss_bus_out(ss_bus_out_stopwatch)
  );

  prog_timer prog_timer (
      .clk(clk),
      .clk_en(clk_en),

      .reset(reset),

      .input_k03(input_k03),

      .mem_reset(reset_prog_timer),
      .enable(enable_prog_timer),
      .clock_selection(prog_timer_clock_selection),
      .counter_reload(prog_timer_reload),

      .reset_factor(reset_prog_timer_factor),
      .factor_flags(prog_timer_factor),

      .downcounter(prog_timer_downcounter),

      // Savestates
      .ss_bus_in(ss_bus_in),
      .ss_bus_addr(ss_bus_addr),
      .ss_bus_wren(ss_bus_wren),
      .ss_bus_reset(ss_bus_reset),
      .ss_bus_out(ss_bus_out_prog_timer)
  );
endmodule
