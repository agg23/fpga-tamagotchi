package ss_addresses;
  parameter SS_BUS_WIDTH = 8;
  parameter SS_DATA_WIDTH = 32;

  // Addresses in savestate
  parameter [SS_BUS_WIDTH-1:0] SS_REGS1 = 8'h0;  // np, pc, a, b, flags
  parameter [SS_BUS_WIDTH-1:0] SS_REGS2 = 8'h1;  // x, y, sp
endpackage
