import ss_addresses::*;

module save_state_controller (
    input wire clk_74a,
    input wire clk_sys,

    input wire reset,

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
    output wire bus_reset,
    input wire [31:0] bus_out,

    input  wire ss_ready,
    output wire ss_halt,
    output wire ss_begin_reset,
    output wire ss_turbo
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

  wire savestate_load_ack;
  wire savestate_load_busy;
  wire savestate_load_ok;
  wire savestate_load_err;

  wire savestate_start_ack;
  wire savestate_start_busy;
  wire savestate_start_ok;
  wire savestate_start_err;

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

  wire fifo_load_read_en;
  wire fifo_load_read_ready;

  wire fifo_save_write_en;
  wire fifo_save_write_ready;

  dcfifo dcfifo_component (
      .data(bridge_wr_data),
      .rdclk(clk_sys),
      .rdreq(fifo_load_read_en),
      .wrclk(clk_74a),
      .wrreq(bridge_wr && bridge_addr[31:28] == 4'h4 && bridge_addr[27:0] < 28'h1D0),
      // Pocket bridge sends big endian
      .q({bus_in[7:0], bus_in[15:8], bus_in[23:16], bus_in[31:24]}),
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
      // Pocket bridge requires big endian
      .data_s({
        save_state_bridge_read_data[7:0],
        save_state_bridge_read_data[15:8],
        save_state_bridge_read_data[23:16],
        save_state_bridge_read_data[31:24]
      }),

      .bridge_rd  (bridge_rd),
      .bridge_addr(bridge_addr)
  );

  savestate_machine savestate_machine (
      .clk(clk_sys),

      .reset(reset),

      // Triggers
      .start_savestate_create(savestate_start_s),
      .start_savestate_load  (savestate_load_s),

      // Flow control
      .data_ready_savestate_load(~fifo_load_read_ready),
      .data_consumed_savestate_create(fifo_save_write_ready),

      // Flow requests
      .req_read_savestate_load(fifo_load_read_en),
      .req_write_savestate_create(fifo_save_write_en),

      // APF signals
      .savestate_load_ack (savestate_load_ack),
      .savestate_load_busy(savestate_load_busy),
      .savestate_load_ok  (savestate_load_ok),
      .savestate_load_err (savestate_load_err),

      .savestate_create_ack (savestate_start_ack),
      .savestate_create_busy(savestate_start_busy),
      .savestate_create_ok  (savestate_start_ok),
      .savestate_create_err (savestate_start_err),

      // Savestates
      .bus_addr (bus_addr),
      .bus_wren (bus_wren),
      .bus_reset(bus_reset),

      .ss_ready(ss_ready),
      .ss_halt(ss_halt),
      .ss_begin_reset(ss_begin_reset),
      .ss_turbo(ss_turbo)
  );

endmodule
