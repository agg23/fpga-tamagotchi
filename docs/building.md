# Building

Building the project is largely self-explanatory; just build as you normally would with Quartus. However, if you wish to change out assets, there are other steps you must take.

## Building Microcode

```bash
cd support
npm run build
```

Alternatively you can directly run the microcode assembler

```bash
cd support
node micro_asm.js ../rtl/core/rom/microcode.asm ../rtl/core/rom/microcode.rom
```

and convert it into hex for ingestion by the tools

```bash
node modelsim.js ../rtl/core/rom/microcode.rom ../rtl/core/rom/microcode.hex 4
```

## Verilator

For Verilator, you probably want to generate hex versions of the [background and sprite assets](tools.md#modelsim-hex-generator-modelsimjs).

### Also see [Tools](tools.md)