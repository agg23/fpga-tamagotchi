import ss_addresses::*;

module bus_memory #(
    parameter MEM_DATA_WIDTH = 4,
    parameter MEM_ADDR_WIDTH,
    parameter [SS_BUS_WIDTH-1:0] ADDRESS_MIN,
    parameter [SS_BUS_WIDTH-1:0] ADDRESS_MAX
) (
    input wire clk,

    /// The data coming in over the data bus
    input wire [SS_DATA_WIDTH-1:0] bus_in,
    /// The address of the data on the bus
    input wire [SS_BUS_WIDTH-1:0] bus_addr,
    /// If set, write this data
    input wire bus_wren,
    /// If set, restore the default value to this register selection
    input wire bus_reset_n,
    /// The data being output at this bus address
    output reg [SS_DATA_WIDTH-1:0] bus_out,

    output wire [MEM_ADDR_WIDTH-1:0] mem_addr,
    input wire [MEM_DATA_WIDTH-1:0] mem_current_data,
    output wire [MEM_DATA_WIDTH-1:0] mem_new_data,
    output reg mem_wren = 0,
    output wire mem_active
);
  localparam WORDS_PER_BUS = SS_DATA_WIDTH / MEM_DATA_WIDTH;
  localparam WORDS_ADDR_WIDTH = $clog2(WORDS_PER_BUS);

  assign mem_active = bus_addr >= ADDRESS_MIN && bus_addr < ADDRESS_MAX;
  wire [SS_BUS_WIDTH-1:0] base_ss_address = mem_active ? bus_addr - ADDRESS_MIN : 0;

  // We use an extra bit to indicate having processed all of the word in the read case
  reg [WORDS_ADDR_WIDTH:0] word_offset = 0;
  reg [SS_BUS_WIDTH-1:0] prev_bus_addr = 0;

  reg [SS_DATA_WIDTH-1:0] buffer = 0;

  localparam STATE_INIT = 0;
  localparam STATE_PROCESSING = 1;
  localparam STATE_FINISHED = 2;

  reg [1:0] state = STATE_INIT;

  assign mem_addr = {base_ss_address, word_offset[WORDS_ADDR_WIDTH-1:0]};

  assign bus_out = buffer;
  assign mem_new_data = buffer[MEM_DATA_WIDTH-1:0];

  always @(posedge clk) begin
    prev_bus_addr <= bus_addr;

    case (state)
      STATE_INIT: begin
        if (mem_active) begin
          // Bus addr is in range. Not reading or writing. Start
          state <= STATE_PROCESSING;

          if (bus_wren) begin
            // Start write
            // Our address is already set for this bus address, so start write
            // mem_new_data will get the lowest word from the data on the bus
            buffer   <= bus_in;
            mem_wren <= 1;
          end else begin
            // Start read
            // We've been at offset 0 until now, increment address early to start next fetch/write
            word_offset <= 1;
          end
        end
      end
      STATE_PROCESSING: begin
        // Both read/write will move to next word
        word_offset <= word_offset + 1;

        // Both paths need to shift by the word size. Read inserts a new word at the top, write uses the lowest word
        buffer <= {mem_current_data, buffer[SS_DATA_WIDTH-1:MEM_DATA_WIDTH]};

        if (bus_wren ? word_offset == WORDS_PER_BUS - 1 : word_offset == WORDS_PER_BUS) begin
          // We've processed all words after this next cycle
          state <= STATE_FINISHED;

          mem_wren <= 0;
        end
      end
      STATE_FINISHED: begin
        // Sit here waiting for an address change
      end
    endcase

    if (~mem_active || (state != STATE_INIT && prev_bus_addr != bus_addr)) begin
      // Reset
      mem_wren <= 0;
      word_offset <= 0;

      state <= STATE_INIT;
    end
  end

endmodule
