module savestate_ddr_controller (
    input wire clk,

    input wire reset,

    // The savestate slot 0-3 to use
    input wire [1:0] slot,

    // Triggers
    input wire start_savestate_create,
    // Reloads the savestate bus registers, triggering the actual load
    input wire start_savestate_load,

    // Savestate Machine
    output reg internal_start_savestate_create = 0,
    output reg internal_start_savestate_load = 0,

    // Flow control
    output reg  data_ready_savestate_load = 0,
    output wire data_consumed_savestate_create,

    // Flow requests
    // Request data after `data_ready_savestate_load`
    input wire req_read_savestate_load,
    // Write data before `data_consumed_savestate_create`
    input wire req_write_savestate_create,

    // DDR
    output wire        DDRAM_CLK,
    input  wire        DDRAM_BUSY,
    output wire [ 7:0] DDRAM_BURSTCNT,
    output wire [28:0] DDRAM_ADDR,
    input  wire [63:0] DDRAM_DOUT,
    input  wire        DDRAM_DOUT_READY,
    output wire        DDRAM_RD,
    output wire [63:0] DDRAM_DIN,
    output wire [ 7:0] DDRAM_BE,
    output wire        DDRAM_WE,

    // Savestates
    output wire [31:0] bus_in,
    input  wire [31:0] bus_out,

    output wire active
);
  // Size is in 32 bit words (dwords)
  localparam SAVESTATE_SIZE = 16'h1D0 / 16'h4;
  // Address is in dwords
  localparam SLOT_SIZE = 16'h1000 / 16'h4;

  // If write_high_dword is low, then we just wrote a whole 64 bits, and the ack is our data_consumed trigger
  // If it's high, we aren't writing anything yet, and we're immediately ready
  // Write has completed when ack goes high
  assign data_consumed_savestate_create = write_high_dword || ddr_ack;

  ////////////////////////////////////////////////////////////////////////////////////////
  // DDR

  wire ddr_ack;

  reg ddr_wr = 0;
  reg ddr_rd = 0;

  reg [63:0] ddr_buffer = 0;
  wire [63:0] ddr_out;
  reg [15:0] ddr_addr = 0;

  // The data coming from the savestate, into the bus
  assign bus_in = ddr_buffer[31:0];

  // This DDRAM exists entirely to act as a cache for savestates. The SS config entry at the
  // very beginning of CONF_STR defines the 0x3E00_0000 block of DDRAM as the savestate write zone
  // We maintain 4 slots, and load/create savestates to this memory, and MiSTer intelligently
  // manages the files
  assign DDRAM_CLK = clk;
  ddram ddram (
      .ch1_addr({11'h380, ddr_addr, 1'b0}),
      .ch1_din(ddr_buffer),
      .ch1_dout(ddr_out),
      .ch1_req(ddr_wr | ddr_rd),
      .ch1_rnw(~ddr_wr),
      .ch1_be(8'hFF),
      .ch1_ready(ddr_ack),

      // DDR ports
      .DDRAM_CLK(DDRAM_CLK),
      .DDRAM_BUSY(DDRAM_BUSY),
      .DDRAM_BURSTCNT(DDRAM_BURSTCNT),
      .DDRAM_ADDR(DDRAM_ADDR),
      .DDRAM_DOUT(DDRAM_DOUT),
      .DDRAM_DOUT_READY(DDRAM_DOUT_READY),
      .DDRAM_RD(DDRAM_RD),
      .DDRAM_DIN(DDRAM_DIN),
      .DDRAM_BE(DDRAM_BE),
      .DDRAM_WE(DDRAM_WE)
  );

  ////////////////////////////////////////////////////////////////////////////////////////
  // DDR State Machine

  // Store the max value, plus one, of all SS counter values. We will use this value as the next SS counter value
  // We start at 0 for every launch, because the savestates are loaded with {32{1'b1}} values
  reg [31:0] max_header_count = 0;

  // Indicates whether we're writing to 31:0, or 63:32
  reg write_high_dword = 0;
  reg read_low_dword = 1;

  reg [3:0] load_req_delay = 0;

  localparam STATE_NONE = 0;
  localparam STATE_CREATE_INIT = 1;
  localparam STATE_CREATE_WAIT = 2;
  localparam STATE_CREATE_WRITE_END = 3;

  localparam STATE_LOAD_VERIFY_SLOT = 4;
  localparam STATE_LOAD_WAIT_DATA = 5;
  localparam STATE_LOAD_WAIT_SS_REQ = 6;
  localparam STATE_LOAD_WAIT_SS_DELAY = 7;

  reg [7:0] state = STATE_NONE;

  assign active = state != STATE_NONE;

  reg prev_start_savestate_create = 0;
  reg prev_start_savestate_load = 0;

  // I feel like this state machine is massively over complicated and should be simplified
  // I'm not going to simplify it though
  always @(posedge clk) begin
    if (reset) begin
      state <= STATE_NONE;

      ddr_wr <= 0;

      internal_start_savestate_create <= 0;
      internal_start_savestate_load <= 0;

      data_ready_savestate_load <= 0;

      max_header_count <= 0;

      write_high_dword <= 0;
      read_low_dword <= 1;
    end else begin
      case (state)
        STATE_NONE: begin
          prev_start_savestate_create <= start_savestate_create;
          prev_start_savestate_load <= start_savestate_load;

          ddr_addr <= slot * SLOT_SIZE;
          ddr_wr <= 0;
          ddr_rd <= 0;

          internal_start_savestate_load <= 0;

          write_high_dword <= 0;
          read_low_dword <= 1;

          if (start_savestate_create && ~prev_start_savestate_create) begin
            // Set up writing savestate size and counter (to indicate new savestate)
            state <= STATE_CREATE_INIT;

            ddr_buffer <= {16'b0, SAVESTATE_SIZE, max_header_count};
            ddr_wr <= 1;
          end else if (start_savestate_load && ~prev_start_savestate_load) begin
            state  <= STATE_LOAD_VERIFY_SLOT;

            // Read SS header
            ddr_rd <= 1;
          end
        end

        // Saving
        STATE_CREATE_INIT: begin
          ddr_wr <= 0;

          // Wait until ack
          if (ddr_ack) begin
            // Start standard SS state machine
            state <= STATE_CREATE_WAIT;

            // We used the last value for this savestate now, increment it
            max_header_count <= max_header_count + 32'h1;

            internal_start_savestate_create <= 1;
          end
        end
        STATE_CREATE_WAIT: begin
          internal_start_savestate_create <= 0;

          // Wait for write from SS machine
          if (req_write_savestate_create) begin
            if (write_high_dword) begin
              state <= STATE_CREATE_WRITE_END;

              ddr_buffer[63:32] <= bus_out;

              // Data is ready to write to RAM
              ddr_wr <= 1;
              ddr_addr <= ddr_addr + 2;
            end else begin
              ddr_buffer[31:0] <= bus_out;
            end

            write_high_dword <= ~write_high_dword;
          end
        end
        STATE_CREATE_WRITE_END: begin
          state  <= STATE_CREATE_WAIT;

          ddr_wr <= 0;

          if (ddr_addr[7:0] == SAVESTATE_SIZE[7:0]) begin
            // We've finished writing out the savestate
            state <= STATE_NONE;
          end
        end

        // Loading
        STATE_LOAD_VERIFY_SLOT: begin
          ddr_rd <= 0;

          if (ddr_ack) begin
            // We've fetched what should be the header. If the upper dword doesn't
            // contain the expected size for a savestate, we abort
            if (ddr_out[63:32] != {16'b0, SAVESTATE_SIZE}) begin
              // This isn't a valid savestate
              state <= STATE_NONE;
            end else begin
              // This could be a valid savestate. Treat it as such
              state <= STATE_LOAD_WAIT_DATA;

              ddr_addr <= ddr_addr + 2;
              ddr_rd <= 1;
            end
          end
        end
        STATE_LOAD_WAIT_DATA: begin
          ddr_rd <= 0;

          // Wait until ack
          if (ddr_ack) begin
            state <= STATE_LOAD_WAIT_SS_REQ;
            // Store read data into buffer
            ddr_buffer <= ddr_out;

            data_ready_savestate_load <= 1;
            read_low_dword <= 1;
          end
        end
        STATE_LOAD_WAIT_SS_REQ: begin
          if (req_read_savestate_load) begin
            // SS controller requested 32 bits of SS data
            // Read is expected to be immediate
            // We don't have to do anything except transition and shift the data
            state <= STATE_LOAD_WAIT_SS_DELAY;

            // Must wait at least 10 cycles for bus_memory writes to finish
            load_req_delay <= 4'hA;

            // This will exhaust all of our stored data, immediately make sure
            // state machine doesn't think we have more
            data_ready_savestate_load <= 0;
          end
        end
        STATE_LOAD_WAIT_SS_DELAY: begin
          if (load_req_delay > 0) begin
            load_req_delay <= load_req_delay - 4'h1;
          end else begin
            // Make sure data was read out, then actually perform shift
            if (read_low_dword) begin
              // First read of 64 bits
              // Ready for another request
              state <= STATE_LOAD_WAIT_SS_REQ;

              ddr_buffer[31:0] <= ddr_buffer[63:32];

              read_low_dword <= 0;

              // We still have more data, mark it
              data_ready_savestate_load <= 1;
            end else begin
              // Second read
              // We need more data
              state <= STATE_LOAD_WAIT_DATA;

              ddr_rd <= 1;
              ddr_addr <= ddr_addr + 2;

              if (ddr_addr[7:0] == SAVESTATE_SIZE[7:0]) begin
                // We've finished reading in the savestate
                state <= STATE_NONE;

                internal_start_savestate_load <= 1;
              end
            end
          end
        end
      endcase
    end
  end

endmodule
