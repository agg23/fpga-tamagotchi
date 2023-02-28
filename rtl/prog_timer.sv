module prog_timer (
    input wire clk,

    input wire reset_n,

    input wire input_k03,

    input wire enable,
    input wire reset,
    input wire [2:0] clock_selection,
    input wire [7:0] counter_reload,

    input  wire reset_factor,
    output reg  factor_flags = 0,

    output reg [7:0] downcounter = 0
);
  reg divider_8khz = 0;
  reg [5:0] counter_8khz = 0;

  // Comb: The input clock for the timer
  reg input_clock = 0;

  reg prev_reset = 0;

  always_comb begin
    case (clock_selection)
      // K03 input
      // TODO: Unused. We don't add noise rejector
      3'b000, 3'b001: input_clock = input_k03;
      // 256Hz
      3'b010: input_clock = counter_8khz[5];
      // 512Hz
      3'b011: input_clock = counter_8khz[4];
      // 1024Hz
      3'b100: input_clock = counter_8khz[3];
      // 2048Hz
      3'b101: input_clock = counter_8khz[2];
      // 4096Hz
      3'b110: input_clock = counter_8khz[1];
      // 8192Hz
      3'b111: input_clock = counter_8khz[0];
    endcase
  end

  wire [7:0] counter_reload_value = counter_reload == 0 ? 8'd255 : counter_reload;

  always @(posedge clk) begin
    prev_reset <= ~reset_n;

    if (~reset_n) begin
      divider_8khz <= 0;
      counter_8khz <= 0;
    end else begin
      // Every 2 ticks, we're at 2x 8,192Hz
      divider_8khz <= ~divider_8khz;

      if (enable && divider_8khz && ~prev_reset) begin
        // Special case to prevent ticking on reset
        counter_8khz <= counter_8khz + 6'h1;
      end
    end
  end

  reg prev_input_clock = 0;

  always @(posedge clk) begin
    if (~reset_n) begin
      downcounter  <= 255;

      factor_flags <= 0;
    end else begin
      prev_input_clock <= input_clock;

      if (enable) begin
        if (~input_clock && prev_input_clock) begin
          downcounter <= downcounter - 8'h1;
        end

        if (downcounter == 0) begin
          // Timer elapsed
          downcounter  <= counter_reload_value;

          factor_flags <= 1;
        end
      end

      if (reset) begin
        downcounter <= counter_reload_value;
      end

      if (reset_factor) begin
        factor_flags <= 0;
      end
    end
  end

endmodule
