module clock (
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
    output wire timer_1hz,

    output reg [7:0] counter_256 = 0
);
  reg prev_reset = 0;

  reg [6:0] divider = 0;

  always @(posedge clk) begin
    prev_reset <= ~reset_n || reset_clock_timer;

    if (~reset_n || reset_clock_timer) begin
      divider <= 0;
      counter_256 <= 0;
    end else begin
      divider <= divider + 1;

      if (divider == 0 && ~prev_reset) begin
        // Special case to prevent ticking on reset
        counter_256 <= counter_256 + 1;
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
endmodule
