module savestate_controller (
    input wire clk,

    input wire reset,

    // The savestate slot 0-3 to use
    input wire [1:0] slot,

    // Triggers
    input wire manual_start_savestate_create,
    input wire auto_start_savestate_create,
    // Reloads the savestate bus registers, triggering the actual load
    input wire manual_start_savestate_load,
    input wire auto_start_savestate_load,

    // SD Saves
    output wire sd_wr,
    output wire sd_rd,

    input wire sd_ack,
    input wire [7:0] sd_buff_addr,
    input wire [15:0] sd_buff_dout,
    output wire [15:0] sd_buff_din,
    input wire sd_buff_wr,

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
    output wire [7:0] bus_addr,
    output wire bus_wren,
    output wire bus_reset,
    input wire [31:0] bus_out,

    input  wire ss_ready,
    output wire ss_halt,
    output wire ss_begin_reset,
    output wire ss_turbo
);
  assign bus_in = ddr_active ? ddr_bus_in : fifo_bus_in;

  wire req_read_savestate_load;
  wire req_write_savestate_create;

  savestate_machine savestate_machine (
      .clk(clk),

      .reset(reset),

      // Triggers
      .start_savestate_create(ddr_start_savestate_create || fifo_start_savestate_create),
      .start_savestate_load  (ddr_start_savestate_load || fifo_start_savestate_load),

      // Flow control
      .data_ready_savestate_load(ddr_data_ready_savestate_load || fifo_data_ready_savestate_load),
      .data_consumed_savestate_create(ddr_data_consumed_savestate_create || fifo_data_consumed_savestate_create),

      // Flow requests
      .req_read_savestate_load(req_read_savestate_load),
      .req_write_savestate_create(req_write_savestate_create),

      // Savestates
      .bus_addr (bus_addr),
      .bus_wren (bus_wren),
      .bus_reset(bus_reset),

      .ss_ready(ss_ready),
      .ss_halt(ss_halt),
      .ss_begin_reset(ss_begin_reset),
      .ss_turbo(ss_turbo)
  );

  wire ddr_active;

  wire ddr_start_savestate_create;
  wire ddr_start_savestate_load;

  wire ddr_data_ready_savestate_load;
  wire ddr_data_consumed_savestate_create;

  wire [31:0] ddr_bus_in;

  savestate_ddr_controller savestate_ddr_controller (
      .clk(clk),

      .reset(reset),

      .slot(slot),

      // Triggers
      .start_savestate_create(manual_start_savestate_create),
      .start_savestate_load  (manual_start_savestate_load),

      // Savestate Machine
      .internal_start_savestate_create(ddr_start_savestate_create),
      .internal_start_savestate_load  (ddr_start_savestate_load),

      // Flow control
      .data_ready_savestate_load(ddr_data_ready_savestate_load),
      .data_consumed_savestate_create(ddr_data_consumed_savestate_create),

      // Flow requests
      .req_read_savestate_load(req_read_savestate_load),
      .req_write_savestate_create(req_write_savestate_create),

      // DDR
      .DDRAM_CLK(DDRAM_CLK),
      .DDRAM_BUSY(DDRAM_BUSY),
      .DDRAM_BURSTCNT(DDRAM_BURSTCNT),
      .DDRAM_ADDR(DDRAM_ADDR),
      .DDRAM_DOUT(DDRAM_DOUT),
      .DDRAM_DOUT_READY(DDRAM_DOUT_READY),
      .DDRAM_RD(DDRAM_RD),
      .DDRAM_DIN(DDRAM_DIN),
      .DDRAM_BE(DDRAM_BE),
      .DDRAM_WE(DDRAM_WE),

      // Savestates
      .bus_in (ddr_bus_in),
      .bus_out(bus_out),

      .active(ddr_active)
  );

  wire fifo_start_savestate_create;
  wire fifo_start_savestate_load;

  wire fifo_data_ready_savestate_load;
  wire fifo_data_consumed_savestate_create;

  wire [31:0] fifo_bus_in;

  savestate_fifo_controller savestate_fifo_controller (
      .clk(clk),

      // Triggers
      .start_savestate_create(auto_start_savestate_create),
      .start_savestate_load  (auto_start_savestate_load),

      // Savestate Machine
      .internal_start_savestate_create(fifo_start_savestate_create),
      .internal_start_savestate_load  (fifo_start_savestate_load),

      // Flow control
      .data_ready_savestate_load(fifo_data_ready_savestate_load),
      .data_consumed_savestate_create(fifo_data_consumed_savestate_create),

      // Flow requests
      .req_read_savestate_load(req_read_savestate_load),
      .req_write_savestate_create(req_write_savestate_create),

      // SD Saves
      .sd_wr(sd_wr),
      .sd_rd(sd_rd),

      .sd_ack(sd_ack),
      .sd_buff_addr(sd_buff_addr),
      .sd_buff_dout(sd_buff_dout),
      .sd_buff_din(sd_buff_din),
      .sd_buff_wr(sd_buff_wr),

      // Savestates
      .bus_in (fifo_bus_in),
      .bus_out(bus_out),

      .ss_ready(ss_ready)
  );

endmodule
