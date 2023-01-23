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
* `NOT` - Invert
* ~~`INC` - Increment by one. Added by me (is this needed?)~~

# Examples

Split into deconstruction of single cycle, and two cycle stages

## `LD X, e` (Load X (low 8 bits) with 8 bit immediate)

### Single Cycle

1. Decode instruction
2. Transfer `e[7:4]` to `XH`
3. Transfer `e[3:0]` to `XL`
4. NOP
5. NOP. Increment PC

### Double Cycle

1. Decode instruction
2. Transfer `e[7:4]` to `XH`
3. Transfer `e[3:0]` to `XL`. Increment PC

## `LD XP, r` (Load X (high 4 bits) with contents of reg)

### Single Cycle

1. Decode instruction
2. Transfer contents of `r` to `XP`. This could be a memory fetch, which will take 1 cycle (mux memory address to be IX (for example), feed into memory, mux memory output onto bus)
3. NOP
4. NOP
5. NOP. Increment PC

### Double Cycle

1. Decode instruction
2. Transfer contents of reg `r` to `XP`
3. NOP Increment PC

## `ADC XH, i` (Add 4 bit immediate with carry to XL)

### Single Cycle

1. Decode instruction
2. Transfer `XH` to `TEMPA`
3. Transfer `i[3:0]` to `TEMPB`
4. Perform ALU `ADD` with carry. Transfer `ALU OUT` to `XL`
5. Copy flags
   * Couldn't this be part of the ALU instruction?
6. NOP
7. NOP. Increment PC

### Double Cycle

1. Decode instruction. Set ALU to `ADD` with carry
2. Transfer `XH` to `TEMPA`
3. Transfer `i[3:0]` to `TEMPB`
4. Transfer `ALU OUT` to `XL` and copy flags. Increment PC

## `LDPX MX, i` (Load M(X) with 4 bit immediate, post increment X)

### Single Cycle

1. Decode instruction
2. Transfer immediate to `M(X)`
3. Increment X
4. NOP
5. NOP. Increment PC

### Double Cycle

1. Decode instruction
2. Transfer immediate to `M(X)`
3. Increment X. Increment PC

## `LBPX MX, e` (Load M(X) with 8 bit immediate, post increment X)

### Single Cycle

1. Decode instruction
2. Transfer `e[3:0]` to `M(X)`
3. Increment X
4. Transfer `e[7:4]` to `M(X)` (now X+1)
5. Increment X. Increment PC

### Double Cycle

1. Decode instruction
2. Transfer `e[3:0]` to `M(X)`. Increment X (done in cycle 2 of step)
3. Transfer `e[7:4]` to `M(X)` (now X+1). Increment X (done in cycle 2 of step). Increment PC

## `ACPX MX, r` (Add with carry contents of reg to M(X))

### Single Cycle

### TODO: Why is this 7 cycles?

1. Decode instruction
2. Transfer `M(X)` to `TEMPA`
3. Tranfer contents of `r` to `TEMPB`
4. Perform ALU `ADD` with carry. Transfer `ALU OUT` to `M(X)` and copy flags
5. Increment X
6. NOP
7. NOP. Increment PC

### Double Cycle

1. Decode instruction. Set ALU to `ADD` with carry
2. Transfer `M(X)` to `TEMPA`
3. Tranfer contents of `r` to `TEMPB`
4. Transfer `ALU OUT` to `M(X)` and copy flags. Increment X. Increment PC

## `INC Mn` (Increment memory `0x0-0xF` specified by `n`)

### Single Cycle

1. Decode instruction
2. Transfer `M(n)` to `TEMPA`
3. Set `TEMPB` to 1
4. Perform ALU `ADD`. Transfer `ALU OUT` to `M(n)`
5. NOP
6. NOP
7. NOP. Increment PC

### Double Cycle

1. Decode instruction. Set ALU to `ADD`
2. Transfer `M(n)` to `TEMPA`
3. Set `TEMPB` to 1
4. Transfer `ALU OUT` to `M(n)`. Increment PC

## `RET` (Return to stack address)

### Double Cycle

1. Decode instruction. Disable PC increment
2. Transfer `M(SP)` to `PCSL`. Increment SP
3. Transfer `M(SP)` (SP + 1) to `PCSH`. Increment SP
4. Transfer `M(SP)` (SP + 2) to `PCP`. Increment SP

## `RETD` (Load 8 bit immediate, increment X by 2, then `RET`)

### Double Cycle

1. Decode instruction. Disable PC increment
   * Duplicate of `RET`
2. Transfer `M(SP)` to `PCSL`. Increment SP
3. Transfer `M(SP)` (SP + 1) to `PCSH`. Increment SP
4. Transfer `M(SP)` (SP + 2) to `PCP`. Increment SP
   * Jump to `LBPX MX, e`
5. Transfer `e[3:0]` to `M(X)`. Increment X
6. Transfer `e[7:0]` to `M(X)` (X + 1). Increment X


Note that this is only 11 cycles, when it should take 12... Is the `RET` microcode not duplicated, and instead there's a 1 cycle jump?

## `RETS` (`RET`, then skip instruction)

### Double Cycle

1. Decode instruction
   * Duplicate of `RET`
2. Transfer `M(SP)` to `PCSL`. Increment SP
3. Transfer `M(SP)` (SP + 1) to `PCSH`. Increment SP
4. Transfer `M(SP)` (SP + 2) to `PCP`. Increment SP
   * Jump to `NOP5`
5. NOP
6. NOP. Increment PC