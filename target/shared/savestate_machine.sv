import ss_addresses::*;

module savestate_machine (
    input wire clk,

    input wire reset,

    // Triggers
    input wire start_savestate_create,
    // Reloads the savestate bus registers, triggering the actual load
    input wire start_savestate_load,

    // Flow control
    // Data has been received from the bridge and is ready to be loaded
    input wire data_ready_savestate_load,
    // The data we're writing to the host system has received the data we sent
    input wire data_consumed_savestate_create,

    // Flow requests
    // Request data after `data_ready_savestate_load`
    output reg req_read_savestate_load = 0,
    // Write data before `data_consumed_savestate_create`
    output reg req_write_savestate_create = 0,

    // APF signals
    output wire savestate_load_ack,
    output wire savestate_load_busy,
    output wire savestate_load_ok,
    output wire savestate_load_err,

    output wire savestate_create_ack,
    output wire savestate_create_busy,
    output wire savestate_create_ok,
    output wire savestate_create_err,

    // Savestates
    output reg [7:0] bus_addr = 0,
    output reg bus_wren = 0,
    output reg bus_reset = 0,

    input  wire ss_ready,
    output reg  ss_halt = 0,
    output reg  ss_begin_reset = 0,
    output wire ss_turbo
);

  reg [3:0] cycle_count = 0;

  localparam STATE_INIT = 0;

  localparam STATE_CREATE_BUSY = 1;
  localparam STATE_CREATE_WAIT_READY = 2;
  localparam STATE_CREATE_DATA = 3;
  localparam STATE_CREATE_WAIT_READ = 4;

  localparam STATE_LOAD_DATA = 5;
  localparam STATE_LOAD_DELAY = 6;
  localparam STATE_LOAD_WAIT_APF = 7;
  localparam STATE_LOAD_BUSY_APF = 8;
  localparam STATE_LOAD_DONE_APF = 9;

  reg [3:0] state = STATE_INIT;

  // Used to delay transitions between APF savestate states. Higher clock speeds require waiting longer than a 74MHz tick
  reg [1:0] apf_delay = 0;

  // Used for SS loading to trigger a halt as soon as ss_ready goes high
  reg halt_when_possible = 0;

  assign ss_turbo = halt_when_possible;

  always @(posedge clk) begin
    if (reset) begin
      bus_addr <= 0;
      bus_wren <= 0;
      // Set high to initialize all registers with their expected defaults
      bus_reset <= 1;

      ss_halt <= 0;
      ss_begin_reset <= 0;

      apf_delay <= 0;
    end else begin
      if (apf_delay > 0) begin
        apf_delay <= apf_delay - 2'h1;
      end

      if (halt_when_possible && ss_ready) begin
        halt_when_possible <= 0;
        ss_halt <= 1;
      end

      case (state)
        STATE_INIT: begin
          ss_halt <= 0;
          ss_begin_reset <= 0;
          bus_reset <= 0;
          bus_addr <= 0;

          if (start_savestate_create) begin
            // Start savestate
            state <= STATE_CREATE_BUSY;
            apf_delay <= 2'h3;

            savestate_create_ack <= 1;
            savestate_create_ok <= 0;
            savestate_create_err <= 0;
            savestate_create_busy <= 0;

            savestate_load_ok <= 0;
            savestate_load_err <= 0;
          end else if (data_ready_savestate_load) begin
            // Load savestate
            // Data has started to be written
            state <= STATE_LOAD_DATA;

            // Start at 255, so addr + 1 = 0;
            bus_addr <= 8'hFF;
            halt_when_possible <= 1;
          end
        end

        // Saving
        STATE_CREATE_BUSY: begin
          if (apf_delay == 0) begin
            state <= STATE_CREATE_WAIT_READY;
            apf_delay <= 2'h3;

            savestate_create_ack <= 0;
            savestate_create_busy <= 1;
          end
        end
        STATE_CREATE_WAIT_READY: begin
          // Wait for savestate halt
          if (ss_ready && apf_delay == 0) begin
            // We're ready to start downloading the savestate
            state <= STATE_CREATE_DATA;

            bus_addr <= 0;
            ss_halt <= 1;
            cycle_count <= 0;

            savestate_create_busy <= 0;
            savestate_create_ok <= 1;
          end
        end
        STATE_CREATE_DATA: begin
          // Wait for 10 cycles to pass
          req_write_savestate_create <= 0;

          cycle_count <= cycle_count + 4'h1;

          if (cycle_count == 9) begin
            // Data should be ready
            req_write_savestate_create <= 1;
          end else if (cycle_count == 10) begin
            // Halt until we're ready to write more
            state <= STATE_CREATE_WAIT_READ;
            cycle_count <= 0;

            bus_addr <= bus_addr + 8'h1;

            if (bus_addr == SS_VIDEO_RAM_END - 8'h1) begin
              // Finished saving savestate
              state <= STATE_INIT;
            end
          end
        end
        STATE_CREATE_WAIT_READ: begin
          if (data_consumed_savestate_create) begin
            // Bridge has read data, we're ready for the next segment
            state <= STATE_CREATE_DATA;
          end
        end

        // Loading
        STATE_LOAD_DATA: begin
          bus_wren <= 0;

          if (data_ready_savestate_load) begin
            // Data is in FIFO
            state <= STATE_LOAD_DELAY;

            req_read_savestate_load <= 1;
          end

          if (bus_addr == SS_VIDEO_RAM_END - 8'h1) begin
            // Finished loading savestate
            state <= STATE_LOAD_WAIT_APF;
          end
        end
        STATE_LOAD_DELAY: begin
          // Data should be loaded from FIFO
          // Write data out to bus
          state <= STATE_LOAD_DATA;

          bus_addr <= bus_addr + 8'h1;

          bus_wren <= 1;
          req_read_savestate_load <= 0;
        end
        STATE_LOAD_WAIT_APF: begin
          // Wait for APF to send load signal
          if (start_savestate_load) begin
            state <= STATE_LOAD_BUSY_APF;
            apf_delay <= 2'h3;

            savestate_load_ack <= 1;
            savestate_load_ok <= 0;
            savestate_load_err <= 0;
            savestate_load_busy <= 0;

            savestate_create_ok <= 0;
            savestate_create_err <= 0;

            ss_begin_reset <= 1;
          end
        end
        STATE_LOAD_BUSY_APF: begin
          if (apf_delay == 0) begin
            state <= STATE_LOAD_DONE_APF;
            apf_delay <= 2'h3;

            savestate_load_ack <= 0;
            savestate_load_busy <= 1;
          end
        end
        STATE_LOAD_DONE_APF: begin
          if (apf_delay == 0) begin
            state <= STATE_INIT;

            savestate_load_busy <= 0;
            savestate_load_ok <= 1;
          end
        end
      endcase
    end
  end

endmodule
