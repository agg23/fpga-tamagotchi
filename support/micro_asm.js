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

const transferRegexSuffix =
  /\s+([a-z0-9\(\)_]+)\s+([a-z0-9\(\)_]+)(?:\s+inc\(([a-z0-9_]+)\))?/i;
const transferRegex = new RegExp("^transfer" + transferRegexSuffix.source, "i");
const transaluRegex = new RegExp("^transalu" + transferRegexSuffix.source, "i");
const jmpRegex = /^jmp\s+(?:(n?(?:c|z))\s+)?#([0-9]+)/i;
const callendRegex = /^callend\s+((?:zero)|(?:copy))/i;
const callstartRegex = /^callstart\s+((?:pcp)|(?:pcsh))/i;
const retendRegex = /^retend\s+((?:pcsh)|(?:pcp))/i;
const haltRegex = /^halt\s*(sleep)?/i;

const regMap = {
  flags: 0,
  a: 1,
  b: 2,
  tempa: 3,
  tempb: 4,
  xl: 5,
  xh: 6,
  xp: 7,
  yl: 8,
  yh: 9,
  yp: 10,
  spl: 11,
  sph: 12,
  mx: 13,
  my: 14,
  msp: 15,
  msp_inc: 16,
  msp_dec: 17,
  mn: 18,
  pcsl: 19,
  pcsh: 20,
  pcp: 21,
  pcp_early: 22,
  nbp: 23,
  npp: 24,
  imml: 25,
  immh: 26,
  hardcoded_1: 27,
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

const aluMap = {
  add: 0,
  add_no_dec: 1,
  adc: 2,
  adc_no_dec: 3,
  sub: 4,
  sub_no_dec: 5,
  sbc: 6,
  and: 7,
  or: 8,
  xor: 9,
  cp: 10,
  rrc: 11,
  rlc: 12,
};

const instructions = {
  "#": {
    type: "regex",
    regex: addressRegex,
    matches: ([_, address]) => {
      // Assign address
      currentAddress = address * 8;
    },
  },
  nop: {
    type: "literal",
    action: (writeWord) => writeWord(0),
  },
  startinterrupt: {
    type: "literal",
    action: (writeWord) => writeWord(parseInt("7000", 16)),
  },
  setpc: {
    type: "literal",
    action: (writeWord) => writeWord(parseInt("6000", 16)),
  },
  transfer: {
    type: "regex",
    regex: transferRegex,
    matches: (matches, writeWord) => {
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
        log(`Could not parse inc "${matches[3]}"`);
      }

      const opcode =
        numberAtBitOffset(1, 13) | // Opcode
        numberAtBitOffset(sourceNum, 8) |
        numberAtBitOffset(destNum, 3) |
        inc;

      writeWord(opcode);
    },
  },
  transalu: {
    type: "regex",
    regex: transaluRegex,
    matches: (matches, writeWord) => {
      let [_, aluOp, dest] = matches;

      const aluOpNum = aluMap[aluOp];
      const destNum = regMap[dest];

      const inc =
        matches.length > 3 && matches[3] !== undefined
          ? regIncMap[matches[3]]
          : 0;

      if (aluOpNum === undefined) {
        log(`Could not parse ALU "${aluOp}"`);
      }

      if (destNum === undefined) {
        log(`Could not parse dest "${dest}"`);
      }

      if (inc === undefined) {
        log(`Could not parse inc "${matches[3]}"`);
      }

      const opcode =
        numberAtBitOffset(1, 14) | // Opcode
        numberAtBitOffset(aluOpNum, 8) |
        numberAtBitOffset(destNum, 3) |
        inc;

      writeWord(opcode);
    },
  },
  jmp: {
    type: "regex",
    regex: jmpRegex,
    matches: ([_, condition, address], writeWord) => {
      const conditional = !!condition;
      const conditionSet = conditional && !condition.startsWith("n");

      const isCarry = conditional && condition.endsWith("c");

      const actualAddress = address * 4;

      const opcode =
        numberAtBitOffset(1, 15) | // Opcode
        numberAtBitOffset(conditional, 12) |
        numberAtBitOffset(isCarry, 11) |
        numberAtBitOffset(conditionSet, 10) |
        actualAddress;

      writeWord(opcode);
    },
  },
  callstart: {
    type: "regex",
    regex: callstartRegex,
    matches: ([_, source], writeWord) => {
      const opcode =
        numberAtBitOffset(5, 13) |
        numberAtBitOffset(1, 11) | // Opcode
        (source === "pcp");

      writeWord(opcode);
    },
  },
  callend: {
    type: "regex",
    regex: callendRegex,
    matches: ([_, copy], writeWord) => {
      const opcode =
        numberAtBitOffset(5, 13) | // Opcode
        (copy === "copy");

      writeWord(opcode);
    },
  },
  retend: {
    type: "regex",
    regex: retendRegex,
    matches: ([_, type], writeWord) => {
      const opcode =
        numberAtBitOffset(11, 12) | // Opcode
        (type === "pcp");

      writeWord(opcode);
    },
  },
  jpbaend: {
    type: "literal",
    action: (writeWord) => writeWord(parseInt("C000", 16)),
  },
  halt: {
    type: "regex",
    regex: haltRegex,
    matches: (matches, writeWord) => {
      const stopOscillator = matches.length > 1 && matches[1] == "sleep";

      const opcode =
        numberAtBitOffset(7, 13) | // Opcode
        stopOscillator;

      writeWord(opcode);
    },
  },
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
  const writeWordWithLog = (word) => writeWord(word, log);

  let matchedLine = false;
  for (const instruction of Object.keys(instructions)) {
    if (line.startsWith(instruction)) {
      matchedLine = true;

      const data = instructions[instruction];
      if (data.type === "literal") {
        data.action(writeWordWithLog);
      } else if (data.type === "regex") {
        if (
          !matchRegex(data.regex, line, (matches) =>
            data.matches(matches, writeWordWithLog)
          )
        ) {
          log(`Could not parse ${instruction.toUpperCase()}`);
        }
      } else {
        log(`Unknown instruction type "${data.type}"`);
      }

      break;
    }
  }

  if (line.length > 0 && !line.startsWith("//") && !matchedLine) {
    log(`Unknown instruction "${line}"`);
  }
};

const parse = async () => {
  const rl = readline.createInterface({
    input: fs.createReadStream(inputFile),
    crlfDelay: Infinity,
  });

  let lineNumber = 0;

  rl.on("line", (line) => parseLine(line.toLowerCase().trim(), ++lineNumber));

  await events.once(rl, "close");

  writeFileSync(outputFile, outputBuffer, { flag: "w" });
};

parse();
