architecture 6200
output "simple_add.rom", create

ld A, 0x5
ld B, 0xB
add A, B

// Must be an even number of instructions so that it takes an integer number of bytes
// Without this nop, the ADD will be cut off
nop5