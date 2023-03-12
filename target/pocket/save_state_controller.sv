import ss_addresses::*;

module save_state_controller (
    input wire clk_74a,
    input wire clk_sys,

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
    output wire [7:0] bus_addr,
    output wire bus_wren,
    output wire bus_reset_n,
    input wire [31:0] bus_out,

    input  wire ss_ready,
    output reg  ss_halt = 0
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

  reg savestate_load_ack;
  reg savestate_load_busy;
  reg savestate_load_ok;
  reg savestate_load_err;

  reg savestate_start_ack;
  reg savestate_start_busy;
  reg savestate_start_ok;
  reg savestate_start_err;

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

  reg  fifo_save_write_en;
  wire fifo_save_write_ready;

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

  // TODO: Remove
  // assign bus_reset_n = 1;

  reg [7:0] ss_addr = 0;
  assign bus_addr = ss_addr;

  reg [3:0] cycle_count = 0;

  localparam STATE_INIT = 0;
  localparam STATE_SAVE_BUSY = 1;
  localparam STATE_SAVE = 2;
  localparam STATE_SAVE_WAIT_READ = 3;

  reg [2:0] state = STATE_INIT;

  always @(posedge clk_sys) begin
    case (state)
      STATE_INIT: begin
        ss_halt <= 0;

        if (savestate_start_s) begin
          // Start savestate
          state <= STATE_SAVE_BUSY;

          savestate_start_ack <= 1;
          savestate_start_ok <= 0;
          savestate_start_err <= 0;
          savestate_start_busy <= 0;

          savestate_load_ok <= 0;
          savestate_load_err <= 0;
        end else if (savestate_load_s) begin
          // TODO: Load savestate
        end
      end
      STATE_SAVE_BUSY: begin
        savestate_start_ack  <= 0;
        savestate_start_busy <= 1;

        // Wait for savestate halt
        if (ss_ready) begin
          // We're ready to start downloading the savestate
          state <= STATE_SAVE;
          ss_addr <= 0;
          ss_halt <= 1;
          cycle_count <= 0;

          savestate_start_busy <= 0;
          savestate_start_ok <= 1;
        end
      end
      STATE_SAVE: begin
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

          ss_addr <= ss_addr + 8'h1;

          if (ss_addr == SS_VIDEO_RAM_END - 8'h1) begin
            // Finished loading savestate
            state   <= STATE_INIT;

            ss_halt <= 0;
          end
        end
      end
      STATE_SAVE_WAIT_READ: begin
        if (fifo_save_write_ready) begin
          // Bridge has read data, we're ready for the next segment
          state <= STATE_SAVE;
        end
      end
    endcase
  end

endmodule
