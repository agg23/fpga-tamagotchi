import fs, { writeFileSync } from "fs";
import { argv } from "process";
import readline from "readline";
import events from "events";

if (argv.length != 4) {
  console.log(`Received ${argv.length - 2} arguments. Expected 2\n`);
  console.log("Usage: node micro_asm.js [input.asm] [output.rom]");

  process.exit(1);
}

const inputFile = argv[2];
const outputFile = argv[3];

const addressRegex = /^#([0-9]+)/i;
const transferRegex =
  /^transfer\s+([a-z\(\)]+)\s+([a-z\(\)]+)(?:\s+inc\(([a-z]+)\))?/i;
const jmpRegex = /^jmp #([0-9]+)/i;

const regMap = {
  flags: 2,
  a: 3,
  b: 4,
  tempa: 5,
  tempb: 6,
  xl: 7,
  xh: 8,
  xp: 9,
  yl: 10,
  yh: 11,
  yp: 12,
  spl: 13,
  sph: 14,
  mx: 15,
  my: 16,
  msp: 17,
  msp_dec: 18,
  mn: 19,
  pcsl: 20,
  pcsh: 21,
  pcp: 22,
  nbp: 23,
  npp: 24,
  imml: 25,
  immh: 26,
  hardcoded1: 27,
  imm_addr_l: 28,
  imm_addr_h: 29,
  imm_addr_p: 30,
};

const regIncMap = {
  xhl: 1,
  yhl: 2,
  sp_inc: 3,
  sp_dec: 4,
};

const outputBuffer = Buffer.alloc(1024);
let currentAddress = 0;

const writeWord = (word, log) => {
  const lower = word & 255;
  const upper = (word >> 8) & 255;

  if (
    outputBuffer[currentAddress] != 0 ||
    outputBuffer[currentAddress + 1] != 0
  ) {
    log(`Data overflowed at address 0x${currentAddress.toString(16)}`);
  }

  outputBuffer[currentAddress] = lower;
  outputBuffer[currentAddress + 1] = upper;

  currentAddress += 2;
};

const numberAtBitOffset = (input, bitOffset) => input << bitOffset;

const matchRegex = (regex, line, closure) => {
  let match = regex.exec(line);

  if (match && match.length > 1) {
    closure(match);
    return true;
  }

  return false;
};

const parseLine = (line, lineNumber) => {
  const log = (message) => {
    console.log(`ERROR (line ${lineNumber}): ${message}`);
  };

  if (
    matchRegex(addressRegex, line, ([_, address]) => {
      // Assign address
      currentAddress = address * 8;

      console.log(`Setting address to ${address}`);
    })
  ) {
    return;
  } else if (line.startsWith("setpc")) {
    console.log(`Setting setpc ${line}`);
    writeWord(parseInt("6000", 16), log);
  } else if (line.startsWith("transfer")) {
    if (
      !matchRegex(transferRegex, line, (matches) => {
        let [_, source, dest] = matches;

        const sourceNum = regMap[source];
        const destNum = regMap[dest];

        const inc =
          matches.length > 3 && matches[3] !== undefined
            ? regIncMap[matches[3]]
            : 0;

        if (sourceNum === undefined) {
          log(`Could not parse source "${source}"`);
        }

        if (destNum === undefined) {
          log(`Could not parse dest "${dest}"`);
        }

        if (inc === undefined) {
          console.log(matches);
          log(`Could not parse inc "${matches[3]}"`);
        }

        const opcode =
          numberAtBitOffset(1, 13) |
          numberAtBitOffset(sourceNum, 8) |
          numberAtBitOffset(destNum, 3) |
          inc;

        writeWord(opcode, log);
        console.log(
          `TRANSFER ${source} ${sourceNum} ${dest} ${destNum} ${matches[3]} inc(${inc})`
        );
      })
    ) {
      log(`Could not parse TRANSFER`);
    }
  } else if (line.startsWith("jmp")) {
    if (
      !matchRegex(jmpRegex, line, ([_, address]) => {
        // TODO
        // const opcode = numberAtBitOffset(4, 13) | numberAtBitOffset()
      })
    ) {
      console.log(`Could not parse JMP`);
    }
  }
};

const parse = async () => {
  const rl = readline.createInterface({
    input: fs.createReadStream(inputFile),
    crlfDelay: Infinity,
  });

  let lineNumber = 0;

  rl.on("line", (line) => parseLine(line.toLowerCase(), ++lineNumber));

  await events.once(rl, "close");

  console.log(outputBuffer[0], outputBuffer[1]);

  writeFileSync(outputFile, outputBuffer, { flag: "w" });
};

parse();
