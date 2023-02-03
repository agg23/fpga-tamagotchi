architecture 6200
output "simple_add.rom", create

// Set all instructions to nop7
fill 8192, 0xFF
origin 0x180 // Start of page 1 (3 nibbles per address)

ld A, 0x7
ld B, 0xB
add A, B

// Must be an even number of instructions so that it takes an integer number of bytes
// Without this nop, the ADD will be cut off
nop5