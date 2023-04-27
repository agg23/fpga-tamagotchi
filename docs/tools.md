# Tools

## Microcode Assembler (micro_asm.js)

Parses the `/rtl/core/rom/microcode.asm` file and produces a binary [microcode](microcode.md). Very simple and has very few features. `#102` starts instruction at position `102 * 4`, and these values (102) map to the instruction decoder. Jumps inside the microcode (which are rare) also use these functions.

## ModelSim HEX Generator (modelsim.js)

Intel's tools have a strange concept of `hex` and stipulate the number of bits that can appear on a line. This tool lets you convert a binary file into hex, while specifying the number of nibbles per line.

```bash
node modelsim.js input.bin output.hex 4
```

The trailing 4 specifies 4 nibbles per line, or 16 bits.

## Image Preparation (prepare_image.js)

The core uses two image formats:

* Background: 16 bit RGB565
* Sprites: 8 bit alphas

This tool converts PNGs to either of those, using the input image dimentions.

To convert a background:

```bash
node prepare_image.js input.png background.bin background
```

And sprites:

```bash
node prepare_image.js input.png sprite.bin sprites
```

## Assembler and Disassember

I also built a 6200 assembler and disassembler, but those tools have now been relocated to the [tamagotchi-disassembled](https://github.com/agg23/tamagotchi-disassembled) project.