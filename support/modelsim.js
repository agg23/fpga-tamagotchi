import { readFileSync, writeFileSync } from "fs";
import { argv } from "process";

if (argv.length != 4) {
  console.log(`Received ${argv.length - 2} arguments. Expected 2\n`);
  console.log("Usage: node modelsim.js [input.asm] [output.sim]");

  process.exit(1);
}

const inputFile = argv[2];
const outputFile = argv[3];

const binaryFile = readFileSync(inputFile);

let outputString = "";

const toHexByte = (number) => {
  let hex = number.toString(16);

  while (hex.length < 2) {
    hex = "0" + hex;
  }

  return hex;
};

for (let i = 0; i < binaryFile.length; i += 2) {
  const byteLo = binaryFile[i];
  const byteHi = binaryFile[i + 1];

  outputString += `${toHexByte(byteHi)}${toHexByte(byteLo)}\n`;
}

writeFileSync(outputFile, outputString);
