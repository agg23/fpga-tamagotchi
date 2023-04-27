# Microcode

The original 6200 CPU architecture clearly was not microcoded given the cycle timing (and the fact that I had to use a 2x clock in order to use a microcode), but it makes the development much cleaner, so that is what I chose to do. The microcode ISA is actually quite simple, given that almost all of the instructions simply transfer data around the bus, which is strongly connected.

See [Tools](tools.md) for information on the assembler.

## Decoder Settings
Global things that are set in decode, instead of being in the microcode

* 1 bit for auto-increment PC
* ~~4 bits for ALU instruction~~

Other things

* Must be able to extract `r` and `q` register immediates into actual A, B, MX, MY 

## Microinstructions

* `NOP`
  * Does nothing for one microcode step
  * `000_00000_00000_000`
* `TRANSFER`
  * Transfers 4 bits from source to dest
  * 5 bits for source
  * 5 bits for dest
  * 3 bits for post-increment specification
  * `001_[source 12:8][dest 7:3][inc 2:0]`
* `TRANSALU`
  * Always has ALU as source
  * ~~1 bit for whether or not to transfer flags~~
  * 4 bits for ALU instruction
  * 5 bits for dest
  * 3 bits for post-increment specification
  * `010_0[ALU 11:8][dest 7:3][inc 2:0]`
* `SETPC`
  * Set 8 bits from immediate to `PCS`
  * Changes to PC are written on the fetch (first half) step, as to set PC before the next instruction is read
  * Cancels PC increment
  * `011_00000_00000_000`
* `STARTINTERRUPT`
  * `TRANSFER PCP MSP_DEC INC(SP_DEC)`
  * Disable interrupt flag
  * `011_10000_00000_000`
* ~~`SETPCVEC`~~
  * Set 12 bit "special" immediate (reset or interrupt vector) to `PC`
  * Changes to PC are written on the fetch (first half) step, as to set PC before the next instruction is read
  * Cancels PC increment
  * `011_10000_00000_000`
* `JMP`
  * 1 bit for conditional. If 1, following two bits are used
  * 1 bit for flag. 0 for zero, 1 for carry
  * 1 bit for set. 0 for unset, 1 for set
  * `x` bits for jump address. If flag matches condition, jump to microaddress
  * `100_[conditional 12:12][flag 11:11][set 10:10][jump addr 9:0]`
* `CALLEND`
  * Special instruction to transfer the low 4 bits of `PC+1` to `M(SP - 1)`, while at the same time copying 8 bit immediate to `PCS`
    * Optionally copies `NPP` to `PCP`
    * Changes to PC are written on the fetch (first half) step, as to set PC before the next instruction is read
  * Decrement SP
  * 1 bit for `NPP` copy. If unset, `PCP` is set to 0, otherwise it's set to `NPP`
  * `101_00000_00000_00[NPP copy 0:0]`
* `CALLSTART`
  * Special instruction to transfer the mid or high 4 bits of `PC+1` to `M(SP - 1)`
  * Decrement SP
  * 1 bit for `PCP` vs `PCSH` copy. If unset, `PCSH` is copied, otherwise `PCP`
  * `101_01000_00000_00[nibble select 0:0]`
* `RETEND`
  * Special instruction to transfer `PCSH` and `PCP` to M(SP + 1) faster than normal
  * Increments SP
  * 1 bit to copy `PCP`. If unset, `PCSH` is copied, and `M(SP+1)` begins loading at `WRITE`. If set, `PCP` is copied, stored on `WRITE`
  * `101_10000_00000_00[PCP copy 0:0]`
* `JPBAEND`
  * Special instruction to transfer `A` to `PCSL` along with transferring the `N*P` values
  * Changes to PC are written on the fetch (first half) step, as to set PC before the next instruction is read
  * `110_00000_00000_000`
* `HALT`
  * Stops the CPU
  * 1 bit to stop peripheral oscillator
  * `111_00000_00000_00[stop oscilllator 0:0]`
