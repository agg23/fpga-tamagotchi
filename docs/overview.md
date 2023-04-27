# Overview
## General Info

* [Building](building.md) - For building the project
* [Arch Overview](arch_overview.md) - Rough overview of registers and ALU operations written at the beginning of the project
* [Microcode](microcode.md) - Spec for the microcode instructions
* [Tests](tests.md) - How to build and run the many tests in the project
* [Tools](tools.md) - Description and usage instructions for the assisting tools in this project

## Implementation

The implementation of this core generally follows directly from the [core architecture specification](62core_e.pdf) and the [specific CPU specification (E0C6S46)](epson%20tm_6s46.pdf). The core arch is implemented entirely in `/rtl/core/`, and the CPU additions to the base arch is specified in the `/rtl/` root.

### Decisions

#### Microcode

I originally wanted to stay as true as possible to the "actual" design the real CPU would have used, but after some prompting by an advisor, I ended up deciding to use microcode as the control system. While it's a lot of work to design your micro-ISA and build the microcode ROM, it ended up being an excellent decision.

Unfortunately, the way this CPU implements its fetch requires the microcode to operate at 2x speed, necessitating a 2x clock. This isn't a huge deal, but it makes the implementation less like the original's, and it forces tighter timing - ultimately I could not reach the max turbo speed I wanted, in part due to this 2x clock requirement.

#### Bad Documentation

* Rotate Instructions - The documentation conflicts on whether or not the `RRC` and `RLC` instructions (rotate with carry) set the zero flag when the output is zero. I disassembled the Tamagotchi ROM and found that this scenario can never come into play; but it makes sense to me that it would set zero (I believe Tamalib does not set it).
* `PSET` Interrupts - I did not see any mention in the documentation about what to do when you interrupt immediately after a `PSET` (therefore having a partial jump). Turns out the processor blocks interrupts until the instruction following the `PSET`.
* `CALL` (and similar) address incrementing - The documentation for `CALL` lists out the operations as something like:
  ```
  MSP <- PCP, MSP <- PCSH, MSP <- PCSL + 1
  ```
  I assumed that this was intentional, weird as it was. In fact, the `CALL` instructions increment the entire 12 bit `{PCP, PCS}` register, and use those effective bit slices to push onto the stack.

* Interrupt duration - I could not figure out how to interpret the cycle counts for interrupts. I have selected 12 cycles as the duration for all interupts, but this may be wrong.

### Unimplemented

* Watchdog - No need for a watchdog timer, as it exists to restart the program, and that's not something the Tamagotchi software does. We omit it as it would just be a waste of FPGA resources
* Buzzer - Lots of the buzzer functionality is unimplemented, including the envelope functions
* Halt - To my surprise, Tamagotchi doesn't use the halt or sleep functionality. This is partially implemented, but untested
* Oscillation control - No need to change clock speeds
* Timers - I believe all timers are fully implemented, but only one or two are actually needed

For unimplemented segments of memory mapped registers, the read and write operations are still implemented with registers that don't do anything. This means writes to these registers can be read back by the core as expected (though the Tamagotchi ROM never does). It also means savestates store and restore those registers.

### Optimization

* Memory/register map - In the initial implementation, some debugging revealed that the inferred memory blocks, and the design of my memory map, was resulting in massive resource usage (around 10% extra of the Pocket). These changes were slowly tested to find the best combination of changes: https://github.com/agg23/fpga-tamagotchi/commit/10c12cedcc141cafae4bc94c1fd8f9371dc6ee0e