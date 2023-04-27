module savestate_fifo_controller (
    input wire clk,

    input wire reset,

    // Triggers
    input wire start_savestate_create,
    input wire start_savestate_load,

    // Savestate Machine
    output reg internal_start_savestate_create = 0,
    output reg internal_start_savestate_load = 0,

    // Flow control
    // Data has been received from the bridge and is ready to be loaded
    output wire data_ready_savestate_load,
    // The data we're writing to the host system has received the data we sent
    output wire data_consumed_savestate_create,

    // Flow requests
    // Request data after `data_ready_savestate_load`
    input wire req_read_savestate_load,
    // Write data before `data_consumed_savestate_create`
    input wire req_write_savestate_create,

    // SD Saves
    output reg sd_wr = 0,
    output reg sd_rd = 0,

    input wire sd_ack,
    input wire [7:0] sd_buff_addr,
    input wire [15:0] sd_buff_dout,
    output wire [15:0] sd_buff_din,
    input wire sd_buff_wr,

    // Savestates
    output wire [31:0] bus_in,
    input  wire [31:0] bus_out,

    input wire ss_ready
);
  // Size is in 16 bit words
  localparam SAVESTATE_SIZE = 16'h1D0 / 16'h2;

  wire load_fifo_empty;

  assign data_ready_savestate_load = ~load_fifo_empty;

  dcfifo_mixed_widths load_fifo (
      .wrclk(clk),
      // MiSTer will read/write an entire block (512 bytes), but we want to stop injesting data
      .wrreq(sd_buff_wr && sd_buff_addr < SAVESTATE_SIZE),
      .data (sd_buff_dout),

      .rdclk(clk),
      .rdreq(req_read_savestate_load),
      .q(bus_in),

      .rdempty(load_fifo_empty),
      .aclr(1'b0)
      // .eccstatus(),
      // .rdfull(),
      // .rdusedw(),
      // .wrempty(),
      // .wrfull(),
      // .wrusedw()
  );

  defparam load_fifo.intended_device_family = "Cyclone V", load_fifo.lpm_numwords = 8,
      load_fifo.lpm_showahead = "OFF", load_fifo.lpm_type = "dcfifo_mixed_widths",
      load_fifo.lpm_width = 16, load_fifo.lpm_widthu = 3, load_fifo.lpm_widthu_r = 2,
      load_fifo.lpm_width_r = 32, load_fifo.overflow_checking = "ON",
      load_fifo.rdsync_delaypipe = 3, load_fifo.underflow_checking = "ON", load_fifo.use_eab = "ON",
      load_fifo.wrsync_delaypipe = 3;

  savestate_save_fifo savestate_save_fifo (
      .clk(clk),

      // Only write if we are definitely using the FIFO path
      .write_en(req_write_savestate_create && state != NONE),
      .bus_out(bus_out),
      .empty(data_consumed_savestate_create),
      .data_out(sd_buff_din),

      .active(sd_ack && state == WRITING),
      .sd_buff_addr(sd_buff_addr)
  );

  localparam NONE = 0;
  localparam WRITING_INIT = 1;
  localparam WRITING = 2;

  localparam READING = 3;

  reg [1:0] state = NONE;

  reg prev_ack = 0;

  always @(posedge clk) begin
    if (reset) begin
      sd_wr <= 0;
      sd_rd <= 0;

      state <= NONE;

      internal_start_savestate_create <= 0;
      internal_start_savestate_load <= 0;
    end else begin
      prev_ack <= sd_ack;

      internal_start_savestate_create <= 0;
      internal_start_savestate_load <= 0;

      if (sd_ack && ~prev_ack) begin
        // Data has started to flow
        sd_wr <= 0;
        sd_rd <= 0;
      end else if (prev_ack && ~sd_ack) begin
        // End of access
        state <= NONE;

        if (state == READING) begin
          // This was a load, trigger the SS machine
          internal_start_savestate_load <= 1;
        end
      end

      case (state)
        NONE: begin
          // Waiting for input
          if (start_savestate_create) begin
            state <= WRITING_INIT;

            // Start SS machine and wait to hit ss_ready
            internal_start_savestate_create <= 1;
          end else if (start_savestate_load) begin
            state <= READING;

            sd_rd <= 1;
          end
        end
        WRITING_INIT: begin
          if (ss_ready) begin
            // Core is ready, now get SD bus ready
            state <= WRITING;

            sd_wr <= 1;
          end
        end
        default: begin
          // Do nothing
        end
      endcase
    end
  end

endmodule
