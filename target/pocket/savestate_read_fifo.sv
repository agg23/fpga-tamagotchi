module savestate_read_fifo #(
    parameter WIDTH = 32
) (
    input wire clk_write,
    input wire clk_read,

    input wire write_en,
    input wire [WIDTH - 1:0] data,
    output wire write_empty,
    output wire [31:0] data_s,

    input wire bridge_rd,
    input wire [31:0] bridge_addr
    // output reg [WIDTH - 1:0] data_s = 0,
    // output reg write_en_s = 0
);

  reg  read_req = 0;

  wire read_empty;

  dcfifo dcfifo_component (
      .data(data),
      .rdclk(clk_read),
      .rdreq(read_req),
      .wrclk(clk_write),
      .wrreq(write_en),
      .q(data_s),
      .rdempty(read_empty),
      .wrempty(write_empty),
      .aclr(),
      .eccstatus(),
      .rdfull(),
      .rdusedw(),
      .wrfull(),
      .wrusedw()
  );
  defparam dcfifo_component.intended_device_family = "Cyclone V", dcfifo_component.lpm_numwords = 4,
      dcfifo_component.lpm_showahead = "OFF", dcfifo_component.lpm_type = "dcfifo",
      dcfifo_component.lpm_width = WIDTH, dcfifo_component.lpm_widthu = 2,
      dcfifo_component.overflow_checking = "ON", dcfifo_component.rdsync_delaypipe = 5,
      dcfifo_component.underflow_checking = "ON", dcfifo_component.use_eab = "ON",
      dcfifo_component.wrsync_delaypipe = 5;

  reg prev_bridge_rd;

  always @(posedge clk_read) begin
    prev_bridge_rd <= bridge_rd && ~read_empty;

    read_req <= 0;

    if (bridge_rd && ~read_empty && ~prev_bridge_rd && bridge_addr[31:28] == 4'h4) begin
      read_req <= 1;
    end
  end

endmodule
