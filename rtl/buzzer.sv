module buzzer (
    input wire clk,
    input wire clk_en,

    input wire reset,

    input wire buzzer_enabled,
    input wire [2:0] buzzer_frequency,

    output reg buzzer_output = 0
);

  reg [3:0] divider = 0;

  function [3:0] frequency_count_value(reg [2:0] frequency_select);
    // Values are calculated by 32768Hz / frequency / 2 - 1
    case (frequency_select)
      // 4096Hz
      0: frequency_count_value = 3;
      // 3276.8Hz
      1: frequency_count_value = 4;
      // 2730.7Hz
      2: frequency_count_value = 5;
      // 2340.6Hz
      3: frequency_count_value = 6;
      // 2048Hz
      4: frequency_count_value = 7;
      // 1638.4Hz
      5: frequency_count_value = 9;
      // 1365.3Hz
      6: frequency_count_value = 11;
      // 1170.3Hz
      7: frequency_count_value = 13;
    endcase
  endfunction

  always @(posedge clk) begin
    if (reset) begin
      divider <= 4;

      buzzer_output <= 0;
    end else if (clk_en) begin
      if (buzzer_enabled) begin
        divider <= divider - 4'h1;

        if (divider == 4'h0) begin
          divider <= frequency_count_value(buzzer_frequency);

          buzzer_output <= ~buzzer_output;
        end
      end else begin
        // Always set counter value
        divider <= frequency_count_value(buzzer_frequency);
        buzzer_output <= 0;
      end
    end
  end

endmodule
