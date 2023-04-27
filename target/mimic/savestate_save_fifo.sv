module savestate_save_fifo (
    input wire clk,

    // Write into save
    input wire write_en,
    input wire [31:0] bus_out,
    output wire empty,
    output wire [15:0] data_out,

    input wire active,
    input wire [7:0] sd_buff_addr
);

  reg read_req = 0;

  dcfifo_mixed_widths save_fifo (
      .wrclk(clk),
      .wrreq(write_en),
      .data (bus_out),

      .rdclk(clk),
      .rdreq(read_req),
      .q(data_out),

      .rdempty(empty),
      .aclr(1'b0)
      // .eccstatus (),
      // .rdfull (),
      // .rdusedw (),
      // .wrfull  (),
      // .wrempty (),
      // .wrusedw ()
  );

  defparam save_fifo.intended_device_family = "Cyclone V", save_fifo.lpm_numwords = 4,
      save_fifo.lpm_showahead = "OFF", save_fifo.lpm_type = "dcfifo_mixed_widths",
      save_fifo.lpm_width = 32, save_fifo.lpm_widthu = 2, save_fifo.lpm_widthu_r = 3,
      save_fifo.lpm_width_r = 16, save_fifo.overflow_checking = "ON",
      save_fifo.rdsync_delaypipe = 3, save_fifo.underflow_checking = "ON", save_fifo.use_eab = "ON",
      save_fifo.wrsync_delaypipe = 3;

  reg [7:0] prev_sd_buff_addr = 0;
  reg prev_active = 0;

  always @(posedge clk) begin
    prev_sd_buff_addr <= sd_buff_addr;
    prev_active <= active;

    read_req <= 0;

    // Start read at the beginning of the active period (there should already be data inside)
    // Otherwise, trigger a read when we move to a new address
    if ((active && ~prev_active) || (~empty && active && sd_buff_addr != prev_sd_buff_addr)) begin
      read_req <= 1;
    end
  end

endmodule
