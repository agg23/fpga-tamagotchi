module clock_divider (
    input wire clk,

    input wire [2:0] turbo_speed,

    input wire ss_halt,
    input wire ss_turbo,
    input wire ss_begin_reset,

    output reg clk_en_32_768khz = 0,
    output reg clk_en_65_536khz = 0
);

  localparam BASE_CLOCK_DIV_COUNT = 12'd3600;

  // Comb
  reg [11:0] clock_div_reset_value;

  always_comb begin
    reg [2:0] combined_turbo;
    // Max out turbo speed when we're waiting for ss_ready
    combined_turbo = ss_turbo ? 3'h4 : turbo_speed;

    case (combined_turbo)
      // 1x
      0: clock_div_reset_value = BASE_CLOCK_DIV_COUNT;
      // 2x
      1: clock_div_reset_value = BASE_CLOCK_DIV_COUNT / 12'd2;
      // 4x
      2: clock_div_reset_value = BASE_CLOCK_DIV_COUNT / 12'd4;
      // 50x
      3: clock_div_reset_value = BASE_CLOCK_DIV_COUNT / 12'd50;
      // 4. Fullspeed. Special value
      default: clock_div_reset_value = 12'd1;
    endcase
  end

  reg [11:0] clock_div = BASE_CLOCK_DIV_COUNT;
  reg [11:0] clock_div_half_reset_value = BASE_CLOCK_DIV_COUNT / 12'h2;
  reg next_tick_is_full = 0;

  reg prev_ss_turbo = 0;

  // Clock divider
  always @(posedge clk) begin
    reg new_next_tick_is_full;

    prev_ss_turbo <= ss_turbo;

    clk_en_32_768khz <= 0;
    clk_en_65_536khz <= 0;

    new_next_tick_is_full = next_tick_is_full;

    if (~ss_halt) begin
      // If halted from savestate, no internal clocks run
      clock_div <= clock_div - 12'h1;

      if (clock_div == 0) begin
        clock_div <= clock_div_reset_value;
        // The halfway point value needs to be latched to prevent skipping or doubling clock ticks
        clock_div_half_reset_value <= clock_div_reset_value == 12'd1 ? 12'd1 : clock_div_reset_value / 12'd2;

        clk_en_32_768khz <= 1;
        clk_en_65_536khz <= 1;
        new_next_tick_is_full = 0;
      end else if (clock_div == clock_div_half_reset_value) begin
        clk_en_65_536khz <= 1;
        new_next_tick_is_full = 1;
      end
    end

    next_tick_is_full <= new_next_tick_is_full;

    if (ss_turbo && ~prev_ss_turbo) begin
      // We need to speed up for SS load so we can halt in the right place. Jump immediately to high speed
      // rather than waiting for it to count down
      clock_div <= next_tick_is_full ? 12'h0 : 12'h1;
      clock_div_half_reset_value <= 12'd1;
    end

    if (ss_begin_reset) begin
      // SS load beginning. Make sure SS ticks align such that this first one is a full tick,
      // and the last (out of 4 used in ss_begin_reset is a 2x tick only)

      // We wait some number of cycles until 0 (the full tick) to prevent congestion/starting too quickly
      clock_div <= 10;
    end
  end

endmodule
