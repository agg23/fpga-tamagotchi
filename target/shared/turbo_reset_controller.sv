module turbo_reset_controller (
    input wire clk,
    input wire clk_en_32_768khz,

    // Settings
    input wire suppress_turbo_after_activation,
    input wire cancel_turbo_on_event,

    input wire [2:0] turbo_speed,
    input wire buzzer,

    input wire manual_reset_turbo,

    output reg reset_turbo = 0
);
  reg prev_turbo_speed_zero = 0;
  reg [19:0] suppress_turbo_counter = 0;

  always @(posedge clk) begin
    reg [19:0] next_suppress_turbo_counter;

    next_suppress_turbo_counter = suppress_turbo_counter;

    reset_turbo <= 0;
    prev_turbo_speed_zero <= turbo_speed == 0;

    // Suppress turbo for a period after activation
    if (turbo_speed > 0 && prev_turbo_speed_zero) begin
      // Turbo was newly activated
      if (suppress_turbo_after_activation) begin
        // 5 seconds at 32kHz
        next_suppress_turbo_counter = 20'h2_8000;
      end
    end

    // Reset turbo on buzzer
    if ((cancel_turbo_on_event && buzzer && next_suppress_turbo_counter == 0) || manual_reset_turbo) begin
      // Reset turbo
      reset_turbo <= 1;
    end

    if (clk_en_32_768khz && suppress_turbo_counter > 0) begin
      // Count in "core" time
      next_suppress_turbo_counter = next_suppress_turbo_counter - 20'h1;
    end

    suppress_turbo_counter <= next_suppress_turbo_counter;
  end

endmodule
