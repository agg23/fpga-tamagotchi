// Set all instructions to nop7
// fill 8192, 0xFF
origin 0x100 // Start of page 1

// Set flags
rst F, 0

ld A, 0 // Accumlator
ld XP, A
ld X, 1 // Going to use MX and MY for temporaries, and access them via M1, M2. MX is iteration count
ld YP, A
ld Y, 2 // MY is prev value

ld MX, 7 // F(n)
ld MY, 1 // F(n-1)

loop:
  ld B, MY // Get prev value
  ld MY, A // Update stored prev value
  adc A, B // Calculate next F value

  dec M1
  cp MX, 0 // Compare to 0

  jp NZ, loop // If not 0, loop

// Calculated
// Store F(n) into M0
ld M0, A