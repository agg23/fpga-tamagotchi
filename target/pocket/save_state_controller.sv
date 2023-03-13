import ss_addresses::*;

module save_state_controller (
    input wire clk_74a,
    input wire clk_sys,

    input wire reset_n,

    // APF
    input wire bridge_wr,
    input wire bridge_rd,
    input wire bridge_endian_little,
    input wire [31:0] bridge_addr,
    input wire [31:0] bridge_wr_data,
    output wire [31:0] save_state_bridge_read_data,

    // APF Savestates
    input  wire savestate_load,
    output wire savestate_load_ack_s,
    output wire savestate_load_busy_s,
    output wire savestate_load_ok_s,
    output wire savestate_load_err_s,

    input  wire savestate_start,
    output wire savestate_start_ack_s,
    output wire savestate_start_busy_s,
    output wire savestate_start_ok_s,
    output wire savestate_start_err_s,

    // Savestates
    output wire [31:0] bus_in,
    output reg [7:0] bus_addr = 0,
    output reg bus_wren = 0,
    output reg bus_reset_n = 0,
    input wire [31:0] bus_out,

    input  wire ss_ready,
    output reg  ss_halt = 0,
    output reg  ss_reset = 0
);
  // Syncing
  wire savestate_load_s;
  wire savestate_start_s;

  synch_3 #(
      .WIDTH(2)
  ) savestate_in (
      {savestate_load, savestate_start},
      {savestate_load_s, savestate_start_s},
      clk_sys
  );

  reg savestate_load_ack = 0;
  reg savestate_load_busy = 0;
  reg savestate_load_ok = 0;
  reg savestate_load_err = 0;

  reg savestate_start_ack = 0;
  reg savestate_start_busy = 0;
  reg savestate_start_ok = 0;
  reg savestate_start_err = 0;

  synch_3 #(
      .WIDTH(8)
  ) savestate_out (
      {
        savestate_load_ack,
        savestate_load_busy,
        savestate_load_ok,
        savestate_load_err,
        savestate_start_ack,
        savestate_start_busy,
        savestate_start_ok,
        savestate_start_err
      },
      {
        savestate_load_ack_s,
        savestate_load_busy_s,
        savestate_load_ok_s,
        savestate_load_err_s,
        savestate_start_ack_s,
        savestate_start_busy_s,
        savestate_start_ok_s,
        savestate_start_err_s
      },
      clk_74a
  );

  reg  fifo_load_read_en;
  wire fifo_load_read_ready;

  reg  fifo_save_write_en;
  wire fifo_save_write_ready;

  dcfifo dcfifo_component (
      .data(bridge_wr_data),
      .rdclk(clk_sys),
      .rdreq(fifo_load_read_en),
      .wrclk(clk_74a),
      .wrreq(bridge_wr && bridge_addr[31:28] == 4'h4 && bridge_addr[27:0] < 28'h1D0),
      .q({
        bus_in[3:0],
        bus_in[7:4],
        bus_in[11:8],
        bus_in[15:12],
        bus_in[19:16],
        bus_in[23:20],
        bus_in[27:24],
        bus_in[31:28]
      }),
      .rdempty(fifo_load_read_ready),
      .wrempty(),
      .aclr(),
      .eccstatus(),
      .rdfull(),
      .rdusedw(),
      .wrfull(),
      .wrusedw()
  );
  defparam dcfifo_component.intended_device_family = "Cyclone V", dcfifo_component.lpm_numwords = 4,
      dcfifo_component.lpm_showahead = "OFF", dcfifo_component.lpm_type = "dcfifo",
      dcfifo_component.lpm_width = 32, dcfifo_component.lpm_widthu = 2,
      dcfifo_component.overflow_checking = "ON", dcfifo_component.rdsync_delaypipe = 5,
      dcfifo_component.underflow_checking = "ON", dcfifo_component.use_eab = "ON",
      dcfifo_component.wrsync_delaypipe = 5;

  save_state_read_fifo fifo_save (
      .clk_write(clk_sys),
      .clk_read (clk_74a),

      .write_en(fifo_save_write_en),
      .data(bus_out),
      .write_empty(fifo_save_write_ready),
      // Pocket bridge requires big endian, by nibble
      .data_s({
        save_state_bridge_read_data[3:0],
        save_state_bridge_read_data[7:4],
        save_state_bridge_read_data[11:8],
        save_state_bridge_read_data[15:12],
        save_state_bridge_read_data[19:16],
        save_state_bridge_read_data[23:20],
        save_state_bridge_read_data[27:24],
        save_state_bridge_read_data[31:28]
      }),

      .bridge_rd  (bridge_rd),
      .bridge_addr(bridge_addr)
  );

  reg [3:0] cycle_count = 0;

  localparam STATE_INIT = 0;

  localparam STATE_SAVE_BUSY = 1;
  localparam STATE_SAVE_DATA = 2;
  localparam STATE_SAVE_WAIT_READ = 3;

  localparam STATE_LOAD_DATA = 4;
  localparam STATE_LOAD_DELAY = 5;
  localparam STATE_LOAD_WAIT_APF = 6;
  localparam STATE_LOAD_BUSY_APF = 7;
  localparam STATE_LOAD_DONE_APF = 8;

  reg [3:0] state = STATE_INIT;

  always @(posedge clk_sys) begin
    if (~reset_n) begin
      bus_addr <= 0;
      bus_wren <= 0;
      // Set low to initialize all registers with their expected defaults
      bus_reset_n <= 0;

      ss_halt <= 0;
      ss_reset <= 0;
    end else begin
      case (state)
        STATE_INIT: begin
          ss_halt <= 0;
          ss_reset <= 0;
          bus_reset_n <= 1;
          bus_addr <= 0;

          if (savestate_start_s) begin
            // Start savestate
            state <= STATE_SAVE_BUSY;

            savestate_start_ack <= 1;
            savestate_start_ok <= 0;
            savestate_start_err <= 0;
            savestate_start_busy <= 0;

            savestate_load_ok <= 0;
            savestate_load_err <= 0;
          end else if (~fifo_load_read_ready) begin
            // Load savestate
            // Data has started to be written
            state <= STATE_LOAD_DATA;

            // Start at 255, so addr + 1 = 0;
            bus_addr <= 8'hFF;
            ss_halt <= 1;
          end
        end

        // Saving
        STATE_SAVE_BUSY: begin
          savestate_start_ack  <= 0;
          savestate_start_busy <= 1;

          // Wait for savestate halt
          if (ss_ready) begin
            // We're ready to start downloading the savestate
            state <= STATE_SAVE_DATA;
            bus_addr <= 0;
            ss_halt <= 1;
            cycle_count <= 0;

            savestate_start_busy <= 0;
            savestate_start_ok <= 1;
          end
        end
        STATE_SAVE_DATA: begin
          // Wait for 10 cycles to pass
          fifo_save_write_en <= 0;

          cycle_count <= cycle_count + 4'h1;

          if (cycle_count == 9) begin
            // Data should be ready
            fifo_save_write_en <= 1;
          end else if (cycle_count == 10) begin
            // Halt until we're ready to write more
            state <= STATE_SAVE_WAIT_READ;
            cycle_count <= 0;

            bus_addr <= bus_addr + 8'h1;

            if (bus_addr == SS_VIDEO_RAM_END - 8'h1) begin
              // Finished saving savestate
              state <= STATE_INIT;
            end
          end
        end
        STATE_SAVE_WAIT_READ: begin
          if (fifo_save_write_ready) begin
            // Bridge has read data, we're ready for the next segment
            state <= STATE_SAVE_DATA;
          end
        end

        // Loading
        STATE_LOAD_DATA: begin
          bus_wren <= 0;

          if (~fifo_load_read_ready) begin
            // Data is in FIFO
            state <= STATE_LOAD_DELAY;

            fifo_load_read_en <= 1;
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
          fifo_load_read_en <= 0;
        end
        STATE_LOAD_WAIT_APF: begin
          // Wait for APF to send load signal
          if (savestate_load_s) begin
            state <= STATE_LOAD_BUSY_APF;

            savestate_load_ack <= 1;
            savestate_load_ok <= 0;
            savestate_load_err <= 0;
            savestate_load_busy <= 0;

            savestate_start_ok <= 0;
            savestate_start_err <= 0;

            ss_reset <= 1;
          end
        end
        STATE_LOAD_BUSY_APF: begin
          state <= STATE_LOAD_DONE_APF;

          savestate_load_ack <= 0;
          savestate_load_busy <= 1;
        end
        STATE_LOAD_DONE_APF: begin
          state <= STATE_INIT;

          savestate_load_busy <= 0;
          savestate_load_ok <= 1;
        end
      endcase
    end
  end

endmodule
