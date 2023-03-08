import getPixels from "get-pixels";
import { globSync } from "glob";
import { argv } from "process";
import { parse, join } from "path";
import { writeFileSync } from "fs";

if (argv.length != 5) {
  console.log(`Received ${argv.length - 2} arguments. Expected 3\n`);
  console.log(
    "Usage: node prepare_image.js [input glob] [ouput path] [background|sprites]"
  );

  process.exit(1);
}

const glob = globSync(argv[2]);

const getDataOptions = () => {
  const isBackground = argv[4] === "background";

  const dataWidth = isBackground ? 2 : 1;

  if (argv[4] === "background") {
    const dataWidth = 2;

    const processPixel = (red, green, blue, _alpha) => {
      // Taken from https://stackoverflow.com/a/9069480
      const red5 = (red * 249 + 1014) >> 11;
      const green6 = (green * 253 + 505) >> 10;
      const blue5 = (blue * 249 + 1014) >> 11;

      const word = (red5 << 11) | (green6 << 5) | blue5;
      return [(word & 0xff00) >> 8, word & 0xff];
    };

    return { dataWidth, processPixel };
  } else {
    // Sprites
    const dataWidth = 1;

    const processPixel = (_red, _green, _blue, alpha) => {
      // Only consider alpha channel
      return [alpha];
    };

    return { dataWidth, processPixel };
  }
};

for (const file of glob) {
  getPixels(file, (err, pixels) => {
    if (err) {
      console.log(`Error loading pixels: ${err}`);
    }

    const { dataWidth, processPixel } = getDataOptions();

    const [width, height] = pixels.shape;

    let outputBuffer = Buffer.alloc(width * height * dataWidth);

    for (let x = 0; x < width; x++) {
      for (let y = 0; y < height; y++) {
        const red = pixels.get(x, y, 0);
        const green = pixels.get(x, y, 1);
        const blue = pixels.get(x, y, 2);
        const alpha = pixels.get(x, y, 3);

        const output = processPixel(red, green, blue, alpha);
        for (let i = 0; i < output.length; i++) {
          const byte = output[i];
          outputBuffer[(y * width + x) * dataWidth + i] = byte;
        }
      }
    }

    // for (const pixel of pixels.)

    const outputFileName = parse(file).name;
    const outputFile = join(argv[3], `${outputFileName}.bin`);

    writeFileSync(outputFile, outputBuffer, { flag: "w" });
  });
}