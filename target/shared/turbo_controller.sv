module turbo_controller (
    input wire clk,

    input wire left_trigger,
    input wire right_trigger,

    input wire reset_turbo,
    input wire set_turbo,
    input wire [2:0] turbo_speed_in,

    output reg [2:0] turbo_speed = 0,
    output reg show_turbo_ui = 0
);

  localparam TURBO_VALUE_COUNT = 4;

  localparam TURBO_BUTTON_DELAY = {25{1'b1}};
  // While > 0, ignore turbo button input
  reg [24:0] turbo_button_counter = 0;

  localparam TURBO_UI_DELAY = {27{1'b1}};
  // While > 0, OSD is up
  reg [26:0] turbo_ui_counter = 0;

  always @(posedge clk) begin
    reg did_use_turbo_button;
    did_use_turbo_button = 0;

    // Timer for how long turbo OSD should stay up
    if (turbo_ui_counter > 0) begin
      turbo_ui_counter <= turbo_ui_counter - 27'h1;
    end else begin
      show_turbo_ui <= 0;
    end

    if (reset_turbo && turbo_speed != 0) begin
      // Reset speed
      // Indicate turbo value changed in UI and add button delay
      did_use_turbo_button = 1;

      turbo_speed <= 0;
    end

    if (turbo_button_counter > 0) begin
      turbo_button_counter <= turbo_button_counter - 25'h1;
    end else begin
      if (left_trigger) begin
        // Left trigger
        did_use_turbo_button = 1;

        if (turbo_speed > 0) begin
          turbo_speed <= turbo_speed - 2'h1;
        end
      end else if (right_trigger) begin
        // Right trigger
        did_use_turbo_button = 1;

        if (turbo_speed < TURBO_VALUE_COUNT) begin
          turbo_speed <= turbo_speed + 2'h1;
        end
      end
    end

    if (set_turbo) begin
      // External set of turbo value
      turbo_speed <= turbo_speed_in;
    end

    if (did_use_turbo_button) begin
      // If we had a button press this cycle, show OSD and start delay preventing button presses
      turbo_button_counter <= TURBO_BUTTON_DELAY;

      show_turbo_ui <= 1;
      turbo_ui_counter <= TURBO_UI_DELAY;
    end

    if (~left_trigger && ~right_trigger) begin
      // Neither L or R pressed, so reset button timer
      turbo_button_counter <= 0;
    end
  end

endmodule
