import ss_addresses::*;

module bus_memory #(
    parameter MEM_DATA_WIDTH = 4,
    parameter MEM_ADDR_WIDTH = 10,
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

  reg [WORDS_ADDR_WIDTH-1:0] word_offset = 0;
  reg [SS_BUS_WIDTH-1:0] prev_bus_addr = 0;

  reg [SS_DATA_WIDTH-1:0] buffer = 0;

  localparam STAGE_INIT = 0;
  localparam STAGE_PROCESSING = 1;
  localparam STAGE_FINISHED = 2;

  reg [1:0] stage = STAGE_INIT;

  assign mem_addr = {base_ss_address, word_offset};

  assign bus_out = buffer;
  assign mem_new_data = buffer[MEM_DATA_WIDTH-1:0];

  always @(posedge clk) begin
    prev_bus_addr <= bus_addr;

    case (stage)
      STAGE_INIT: begin
        if (mem_active) begin
          // Bus addr is in range. Not reading or writing. Start
          stage <= STAGE_PROCESSING;

          if (bus_wren) begin
            // Start write
            // Our address is already set for this bus address, so start write
            // mem_new_data will get the lowest word from the data on the bus
            buffer   <= bus_in;
            mem_wren <= 1;
          end else begin
            // Start read
            // Do nothing special
          end
        end
      end
      STAGE_PROCESSING: begin
        // Both read/write will move to next word
        word_offset <= word_offset + 1;

        // Both paths need to shift by the word size. Read inserts a new word at the top, write uses the lowest word
        buffer <= {mem_current_data, buffer[SS_DATA_WIDTH-1:MEM_DATA_WIDTH]};

        if (word_offset == WORDS_PER_BUS - 1) begin
          // We've processed all words after this next cycle
          stage <= STAGE_FINISHED;

          mem_wren <= 0;
        end
      end
      STAGE_FINISHED: begin
        // Sit here waiting for an address change
      end
    endcase

    if (~mem_active || (stage != STAGE_INIT && prev_bus_addr != bus_addr)) begin
      // Reset
      mem_wren <= 0;
      word_offset <= 0;

      stage <= STAGE_INIT;
    end

    // if (~mem_active) begin
    //   // Reset
    //   mem_wren <= 0;
    //   word_offset <= 0;
    //   processing <= 0;
    // end else if (~processing) begin
    //   // Not reading or writing. Start
    //   processing <= 1;

    //   if (bus_wren) begin
    //     // Start write
    //     // Our address is already set for this bus address, so start write
    //     // mem_new_data will get the lowest word from the data on the bus
    //     buffer   <= bus_in;
    //     mem_wren <= 1;
    //   end else begin
    //     // Start read
    //     // Do nothing special
    //   end
    // end else begin
    //   // Both read/write will move to next word
    //   word_offset <= word_offset + 1;

    //   // Both paths need to shift by the word size. Read inserts a new word at the top, write uses the lowest word
    //   buffer <= {mem_current_data, buffer[SS_DATA_WIDTH-1:MEM_DATA_WIDTH]};

    //   if (word_offset == WORDS_PER_BUS - 1) begin
    //     // We've processed all words after this next cycle

    //   end
    // end

    // case (stage)
    //   STAGE_INIT: begin
    //     if (mem_active) begin
    //       // Start loading this memory address
    //       // Address is already being output for read
    //       stage <= STAGE_PROCESSING;
    //     end
    //   end
    //   STAGE_PROCESSING: begin
    //     if (~mem_active) begin
    //       // We're out of bounds. Reset
    //       reset = 1;
    //     end else if (bus_wren) begin
    //       word_offset <= word_offset + 1;

    //       mem_wren <= 1;

    //     end else begin
    //       // Data for read is ready
    //       // Shift new data in
    //       buffer[SS_DATA_WIDTH-1:0] <= {mem_current_data, buffer[SS_DATA_WIDTH-1:MEM_DATA_WIDTH]};

    //       word_offset <= word_offset + 1;

    //       if (word_offset == WORDS_PER_BUS) begin
    //         // We've processed all words
    //         stage <= STAGE_FINISHED;
    //       end
    //     end
    //   end
    //   STAGE_FINISHED: begin
    //     // TODO: Do we need this?
    //     reset = 1;
    //   end
    // endcase

    // if (reset) begin
    //   word_offset <= 0;
    //   mem_wren <= 0;

    //   stage <= STAGE_INIT;
    // end

    // if (mem_active) begin
    //   prev_bus_addr <= bus_addr;

    //   // Increment word_offset
    //   word_offset   <= word_offset + 1;

    //   if (bus_addr != prev_bus_addr) begin
    //     // Bus address has changed. Reset
    //     word_offset <= 0;
    //   end

    //   if (bus_wren) begin
    //     // Writing to memory
    //   end else begin
    //     // Reading from memory

    //   end
    // end
  end

endmodule
