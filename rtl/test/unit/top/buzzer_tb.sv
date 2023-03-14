`include "vunit_defines.svh"

module buzzer_tb;
  bench bench();

  task test_buzzer_frequencies(reg [2:0] clock_selection, int duration);
    bench.initialize(12'hFFF); // NOP7
    bench.cpu_uut.buzzer_frequency_selection = {1'b1, clock_selection};

    #1;
    bench.cpu_uut.buzzer_output_control = 4'h7;

    // Wait for first tick
    #(duration - 2);
    `CHECK_EQUAL(bench.cpu_uut.buzzer, 0);
    
    #2;

    `CHECK_EQUAL(bench.cpu_uut.buzzer, 1);

    // Test second tick
    #(duration - 2);

    `CHECK_EQUAL(bench.cpu_uut.buzzer, 1);

    #2;

    `CHECK_EQUAL(bench.cpu_uut.buzzer, 0);

    // Third tick
    #(duration - 2);
    `CHECK_EQUAL(bench.cpu_uut.buzzer, 0);
    
    #2;

    `CHECK_EQUAL(bench.cpu_uut.buzzer, 1);

    // Fourth tick
    #(duration - 2);

    `CHECK_EQUAL(bench.cpu_uut.buzzer, 1);

    #2;

    `CHECK_EQUAL(bench.cpu_uut.buzzer, 0);
  endtask

  `TEST_SUITE begin
    `TEST_CASE("Buzzer 0 should fire at 4096Hz") begin
      test_buzzer_frequencies(3'h0, 8 * 2);
    end

    `TEST_CASE("Buzzer 1 should fire at 3276.8Hz") begin
      test_buzzer_frequencies(3'h1, 10 * 2);
    end

    `TEST_CASE("Buzzer 2 should fire at 2730.7Hz") begin
      test_buzzer_frequencies(3'h2, 12 * 2);
    end

    `TEST_CASE("Buzzer 3 should fire at 2340.6Hz") begin
      test_buzzer_frequencies(3'h3, 14 * 2);
    end

    `TEST_CASE("Buzzer 4 should fire at 2048Hz") begin
      test_buzzer_frequencies(3'h4, 16 * 2);
    end

    `TEST_CASE("Buzzer 5 should fire at 1638.4Hz") begin
      test_buzzer_frequencies(3'h5, 20 * 2);
    end

    `TEST_CASE("Buzzer 6 should fire at 1365.3Hz") begin
      test_buzzer_frequencies(3'h6, 24 * 2);
    end

    `TEST_CASE("Buzzer 7 should fire at 1170.3Hz") begin
      test_buzzer_frequencies(3'h7, 28 * 2);
    end
  end;

  // The watchdog macro is optional, but recommended. If present, it
  // must not be placed inside any initial or always-block.
  `WATCHDOG(1ns);
endmodule
