module interrupt (
    input wire clk,

    input wire reset_n,

    // Clock
    input wire timer_32hz,
    input wire timer_8hz,
    input wire timer_2hz,
    input wire timer_1hz,

    // Factor flags
    input wire reset_clock_factor,
    output reg [3:0] clock_factor = 0
);
  reg prev_timer_32hz = 0;
  reg prev_timer_8hz = 0;
  reg prev_timer_2hz = 0;
  reg prev_timer_1hz = 0;

  always @(posedge clk) begin
    if (~reset_n) begin
      prev_timer_32hz <= 0;
      prev_timer_8hz <= 0;
      prev_timer_2hz <= 0;
      prev_timer_1hz <= 0;

      clock_factor <= 0;
    end else begin
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

endmodule
