# Registers

## Instruction Register (IR)

12 bit

Reads all 12 bits at once from ROM. Feeds into instruction decoder

## PC Block (PC*, NBP, NPP)

| Register               | Size  |
|------------------------|-------|
| `PCB` (Bank)             | 1 bit |
| `PCP` (Page)             | 4 bit |
| `PCS` (Step)             | 8 bit |
| `NBP` (New Bank Pointer) | 1 bit |
| `NPP` (New Page Pointer) | 4 bit |

* On non-jump instruction execute, `PCP + PCS` (12 bits) are incremented by 1 (wrapping outside of bank, so you can't auto-increment a bank change)
* `NBP` and `NPP` (5 bits) represent the potential future result of a `PSET` followed by a jump. `PSET` sets these registers, and the values are consumed by a jump
  * "The contents of `NBP` and `NPP` are loaded into `PCB` and `PCP` each time an instruction is executed" - It's unclear how this is reconciled with the incrementing `PCP + PCS`. Similarly, how does the bank/page change from `PSET` only take effect when immediately followed by a jump if these values are always transferred?
* `PSET` followed by `CALZ` ignores the bank/page set by `PSET`

Note: `PCP` and `PCS` are denoted in the docs as being "counter"s, not registers. Unclear why this is distinguished

## Index Register X (IX)

12 bit

Split into high 4 bits (`XP`), and lower 8 bits (`XHL`). `XHL` is divided into high (`XH`) and low (`XL`).

* `XHL` can be incremented by 1 or 2 using a post-increment instruction (`LDPX`, etc...). This wraps without affecting `XP`
  * This appears to use dedicated hardware

### MX

* `MX` - The memory address pointed to by `IX`
* `M(X)` - The contents of memory at `MX`

## Index Register Y (IY)

12 bit

Split into high 4 bits (`YP`), and lower 8 bits (`YHL`). `YHL` is divided into high (`YH`) and low (`YL`).

* `YHL` can be incremented by 1 using a post-increment instruction (`LDPY`, etc...). This wraps without affecting `YP`
  * This appears to use dedicated hardware

### MY

* `MY` - The memory address pointed to by `IY`
* `M(Y)` - The contents of memory at `MY`

## Stack Pointer (SP)

8 bit

When addressing memory, the upper 4 bits of the address are 0, so SP can only address the first 256 words `0x0-0xFF`

## Register Pointer (RP)

4 bit

When used (i.e. this is optional), the first 16 words of memory can be reserved as a psuedo-register block (`0x0-0xF`)

* `RP` is not directly accessed, but is indicated by certain `LD`, `INC`, `DEC` instructions

## Accumulator Registers (A/B)

4 bit

Internal to the ALU, the `A`/`B` registers are used as accumulators

Usage:
* Most instructions reference them as the `r[1:0]` or `q[1:0]` immediate
  | R/Q | Reg |
  |-----|-----|
  | 0   | A   |
  | 1   | B   |
  | 2   | MX  |
  | 3   | MY  |

* The `A` and `B` registers can be used in conjunction for a jump using `JPBA`

# ALU

Contains the `TEMPA` and `TEMPB` registers. They appear to only be used to store the input value on the ALU bus (so the contents of some register that's feeding into the ALU). Diagram shows the carry output from the ALU feeding into `TEMPB`, so maybe there's some scenario where the carry value is used in an accumlator like fashion; instruction performs some operation, takes the result (with carry), and uses it for another operation, then the instruction ends

## Operations

Each operation consumes values from the bus (into `TEMPA/B`), and stores the output into a bus register (including `TEMPA/B`). Multiple operations may occur per instruction

* `ADD` - Can add with/without carry
* `SUB` - Can sub with/without borrow (carry)
* `AND`
* `OR`
* `XOR`
* `CP` - Comparison
* `FAN` - `AND` without store (for setting flags)
* `RRC` - Rotate right with carry
* `RLC` - Rotate left with carry
* ~~`NOT` - Invert~~
* ~~`INC` - Increment by one. Added by me (is this needed?)~~

# Microcode

### Decoder Settings
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
  * Special instruction to transfer `PCSL+1` to `M(SP - 1)`, while at the same time copying 8 bit immediate to `PCS`
    * Optionally copies `NPP` to `PCP`
    * Changes to PC are written on the fetch (first half) step, as to set PC before the next instruction is read
  * Decrement SP
  * 1 bit for `NPP` copy. If unset, `PCP` is set to 0, otherwise it's set to `NPP`
  * `101_00000_00000_00[NPP copy 0:0]`
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
