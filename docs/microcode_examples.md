# Microcode Examples

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
3. NOP. Increment PC

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

## `SET F, i` (Set flags using immediate)

Shares opcode prefix with all flag setters (they just hardcode the immediate)

### Double Cycle

1. Decode instruction. Set `ALU` to `OR`
2. Transfer `i[3:0]` to `TEMPA`
3. Transfer `F` to `TEMPB`
4. Transfer `ALU OUT` to `F`. Increment PC

## `JP C, s` (Jump to 8 bit immediate if carry set)

### Double Cycle

1. Decode instruction
2. Jump if carry set
3. If carry set, set `PCS` to immediate
   * If carry unset, NOP. Increment PC