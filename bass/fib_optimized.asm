// Page 0
add_8:
  // A, B contain the low nibble of the addends
  // M6, M7 contain the high nibble of the addends
  // Uses M15 as temporary
  // Returns the result with B as the high nibble, and A as the low nibble
  rst F, 0xE // Reset carry
  adc A, B // Add low nibbles
  ld M15, A // Transfer low result to M15 temp

  ld A, M6 // Load high nibbles
  ld B, M7

  adc A, B // Add high nibbles
  ld B, A // Transfer high result to B
  ld A, M15 // Transfer low result to A

  ret

origin 0x100 // Start of page 1 and vector table

constant start

origin 0x110 // End of vector table

start:
rst F, 0 // Set flags

// M0-1 is result (M0 high, M1 low)
// M2 is number of iterations, also accessed as MX
// M3-4 is the prev fib number (M3 high, M4 low)
// M5 is the high nibble of F(n)

// Initialize SP to 0xFF
ld A, 0xF
ld SPH, A
ld SPL, A

ld A, 1
ld M4, A // F(n-1) - Prev Fibonacci number low nibble

ld A, 0 // Accumlator
ld B, 0 // Accumulator high
ld M3, A // F(n-1) - High nibble

ld XP, A
ld X, 2 // MX is iteration count

ld MX, 10 // n - nth Fibonacci number

loop:
  ld M6, B // Store high current value

  // Get prev value
  ld B, M3 // High nibble
  ld M7, B // Transfer prev high nibble to M7
  ld B, M4 // Low nibble

  // Store current value
  ld M4, A // Store low prev value
  ld A, M6 // Get high value
  ld M3, A // Store high prev value

  // M7, B has old prev value
  ld A, M4 // M6, A has current value

  ; nop5
  ; nop5
  ; nop5
  ; nop5
  ; nop5
  ; nop5
  ; nop5
  ; nop5
  ; nop5
  ; nop5
  ; nop5
  ; nop5
  ; nop5
  ; nop5

  calz add_8

  dec M2
  cp MX, 0 // Compare to 0

  jp NZ, loop // If not 0, loop

// Calculation complete
// Store F(n) into M1-0
ld M0, B
ld M1, A
halt