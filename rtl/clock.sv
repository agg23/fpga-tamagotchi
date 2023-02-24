module clock (
    input wire clk,

    input wire reset_n,

    output wire timer_128hz,
    output wire timer_64hz,
    output wire timer_32hz,
    output wire timer_16hz,
    output wire timer_8hz,
    output wire timer_4hz,
    output wire timer_2hz,
    output wire timer_1hz
);
  reg prev_reset_n = 0;

  reg [6:0] divider = 0;
  reg [7:0] counter = 0;

  always @(posedge clk) begin
    prev_reset_n <= reset_n;

    if (~reset_n) begin
      divider <= 0;
      counter <= 0;
    end else begin
      divider <= divider + 1;

      if (divider == 0 && prev_reset_n) begin
        // Special case to prevent ticking on reset
        counter <= counter + 1;
      end
    end
  end

  assign timer_128hz = counter[0];
  assign timer_64hz  = counter[1];
  assign timer_32hz  = counter[2];
  assign timer_16hz  = counter[3];
  assign timer_8hz   = counter[4];
  assign timer_4hz   = counter[5];
  assign timer_2hz   = counter[6];
  assign timer_1hz   = counter[7];
endmodule
