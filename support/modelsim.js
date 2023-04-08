import { readFileSync, writeFileSync } from "fs";
import { argv } from "process";

if (argv.length != 5) {
  console.log(`Received ${argv.length - 2} arguments. Expected 3\n`);
  console.log(
    "Usage: node modelsim.js [input.bin] [output.hex] [# of nibbles per line (you probably want 4)]"
  );

  process.exit(1);
}

const inputFile = argv[2];
const outputFile = argv[3];
const nibblePerLine = parseInt(argv[4], 10);

const binaryFile = readFileSync(inputFile);

let outputString = "";
let nibbleString = "";

const toHexByte = (number) => {
  let hex = number.toString(16);

  while (hex.length < 2) {
    hex = "0" + hex;
  }

  return hex;
};

for (let i = 0; i < binaryFile.length; i++) {
  const byte = binaryFile[i];
  nibbleString += toHexByte(byte);
}

for (let i = 0; i < nibbleString.length; i += nibblePerLine) {
  let line = "";

  const lineLength = Math.min(nibblePerLine, nibbleString.length - i);

  for (let j = 0; j < lineLength; j++) {
    const nibbleChar = nibbleString[i + j];

    line += nibbleChar;
  }

  outputString += `${line}\n`;
}

writeFileSync(outputFile, outputString);
