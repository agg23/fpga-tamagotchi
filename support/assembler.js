import fs, { readFileSync, writeFileSync } from "fs";
import { argv } from "process";
import readline from "readline";
import events from "events";

const archPath = "../bass/architectures/6200.arch";

const whitespaceRegex = /\s+/g;
const numberRegex = /\*([0-9]+)/;
const labelRegex = /^([a-z0-9_]+):/i;
const commentRegex = /(\/\/.*)/;

const supportedInstructions = [];

const matchedInstructions = [];
const matchedLabels = {};

const outputBuffer = Buffer.alloc((8192 * 3) / 2);
let currentAddress = 0;

const commands = [
  {
    regex: /origin\s+((?:0x)?[a-f0-9]+)/,
    action: (_, [_2, address]) => {
      currentAddress = parseNumber(address);
    },
  },
  {
    regex: /constant\s+(?:(0x[a-f0-9]+|[0-9]+)|([a-z0-9_]+))/,
    action: ({ line, lineNumber }, [_, constant, label]) => {
      if (constant !== undefined) {
        const value = parseNumber(constant);

        if (value > 4095) {
          log(
            `Constant ${constant} is too large to fit into 12 bits`,
            lineNumber
          );
          return;
        }

        matchedInstructions.push({
          type: "constant",
          subtype: "literal",
          value,
          line,
          lineNumber,
          address: currentAddress,
        });
      } else if (label !== undefined) {
        matchedInstructions.push({
          type: "constant",
          subtype: "label",
          label,
          line,
          lineNumber,
          address: currentAddress,
        });
      } else {
        log("Unknown constant error", lineNumber);
        return;
      }

      currentAddress += 1;
    },
  },
];

const log = (message, lineNumber) =>
  console.log(`ERROR (line ${lineNumber}): ${message}`);

const parseNumber = (string) => {
  if (string.startsWith("0x")) {
    return parseInt(string.substring(2), 16);
  } else {
    return parseInt(string, 10);
  }
};

const parseArchLine = (line, lineNumber) => {
  if (line.length == 0 || line.startsWith("//") || line.startsWith("#")) {
    // Comment. Skip
    return;
  }

  const sections = line.split(";");

  if (sections.length != 2) {
    log(
      "Unexpected semicolon. Does this instruction have an output?",
      lineNumber
    );

    return;
  }

  const [originalInstruction, opcode] = sections;

  let numberMatch = originalInstruction.match(numberRegex);

  if (!!numberMatch) {
    const matchString = numberMatch[0];
    const bitCount = numberMatch[1];
    const index = numberMatch.index;

    let instructionLine =
      originalInstruction.substring(0, index) +
      "(?:(0x[a-f0-9]+|[0-9]+)|([a-z0-9_]+))" +
      originalInstruction.substring(index + matchString.length);

    instructionLine = instructionLine
      .trim()
      .replace(whitespaceRegex, whitespaceRegex.source);

    supportedInstructions.push({
      type: "immediate",
      regex: new RegExp(instructionLine),
      bitCount,
      opcodeString: opcode.trim(),
    });

    return;
  }

  const instructionLine = originalInstruction
    .trim()
    .replace(whitespaceRegex, whitespaceRegex.source);

  supportedInstructions.push({
    type: "literal",
    regex: new RegExp(instructionLine),
    opcodeString: opcode.trim(),
  });
};

let unmatchedLabels = [];

const parseAsmLine = (line, lineNumber) => {
  if (line.length == 0 || line.startsWith("//") || line.startsWith(";")) {
    // Comment. Skip
    return;
  }

  for (const command of commands) {
    const matches = command.regex.exec(line);

    if (!!matches && matches.length > 0) {
      command.action({ lineNumber, line }, matches);
      return;
    }
  }

  let hasInstruction = false;

  for (const instruction of supportedInstructions) {
    const matches = instruction.regex.exec(line);

    if (!!matches && matches.length > 0) {
      if (matches[1] !== undefined) {
        // immediate
        matchedInstructions.push({
          type: "immediate",
          line,
          immediate: parseNumber(matches[1]),
          opcodeString: instruction.opcodeString,
          bitCount: instruction.bitCount,
          lineNumber,
          address: currentAddress,
        });
      } else if (matches[2] !== undefined) {
        // potential label
        matchedInstructions.push({
          type: "label",
          line,
          label: matches[2],
          opcodeString: instruction.opcodeString,
          bitCount: instruction.bitCount,
          lineNumber,
          address: currentAddress,
        });
      } else {
        // literal only
        matchedInstructions.push({
          type: "literal",
          line,
          opcodeString: instruction.opcodeString,
          lineNumber,
          address: currentAddress,
        });
      }

      hasInstruction = true;
      currentAddress += 1;
      break;
    }
  }

  if (hasInstruction && unmatchedLabels.length > 0) {
    // Add queued labels
    for (const label of unmatchedLabels) {
      if (matchedLabels[label.label]) {
        log(
          `Label "${label.label}" already exists. Was created on line ${
            matchedLabels[label.label].lineNumber
          }`,
          lineNumber
        );

        return;
      }

      matchedLabels[label.label] = {
        lineNumber,
        instructionIndex: matchedInstructions.length - 1,
        address: currentAddress - 1,
      };
    }

    unmatchedLabels = [];
  }

  let lineWithoutLabel = line;

  const matches = labelRegex.exec(line);

  if (!!matches && matches.length > 0) {
    lineWithoutLabel =
      lineWithoutLabel.substring(0, matches.index) +
      lineWithoutLabel.substring(matches.index + matches[0].length);

    const label = matches[1];
    if (matchedLabels[label]) {
      log(
        `Label "${label}" already exists. Was created on line ${matchedLabels[label].lineNumber}`,
        lineNumber
      );

      return;
    }

    if (hasInstruction) {
      // Instruction on this line, pair them up
      matchedLabels[label] = {
        lineNumber,
        instructionIndex: matchedInstructions.length - 1,
        address: currentAddress - 1,
      };
    } else {
      // Will pair with some future instruction. Queue it
      unmatchedLabels.push({
        label,
        lineNumber,
      });
    }
  }

  lineWithoutLabel = lineWithoutLabel.replace(commentRegex, "").trim();

  if (!hasInstruction && lineWithoutLabel.length > 0) {
    log(`Unknown instruction "${lineWithoutLabel}"`, lineNumber);
  }
};

const maskOfSize = (size) => {
  let mask = 0;
  for (let i = 0; i < size; i++) {
    mask <<= 1;
    mask |= 1;
  }

  return mask;
};

const buildOpcode = (template, argSize, argument) => {
  let index = 0;
  let outputWord = 0;

  while (index < template.length) {
    const char = template[index];

    if (char === "%") {
      // Consume the next four chars as bits
      const nibble = parseInt(template.substring(index + 1, index + 1 + 4), 2);

      outputWord <<= 4;
      outputWord |= nibble;

      index += 4;
    } else if (char === "=") {
      if (template[index + 1] !== "a") {
        console.log(
          `ERROR: Unexpected char after = in instruction definition "${template}"`
        );
        return 0;
      }

      outputWord <<= argSize;
      outputWord |= maskOfSize(argSize) & argument;

      index += 2;
    } else {
      index += 1;
    }
  }

  return outputWord;
};

const outputInstructions = () => {
  const threeNibbleBuffer = new Array(8192 * 3);

  // Fill array with 0xF
  for (let i = 0; i < threeNibbleBuffer.length; i++) {
    threeNibbleBuffer[i] = 0xf;
  }

  for (const instruction of matchedInstructions) {
    let opcode = 0;
    switch (instruction.type) {
      case "literal": {
        opcode = buildOpcode(instruction.opcodeString, 0, 0);
        break;
      }
      case "immediate": {
        opcode = buildOpcode(
          instruction.opcodeString,
          instruction.bitCount,
          instruction.immediate
        );
        break;
      }
      case "label": {
        const label = matchedLabels[instruction.label];

        if (!label) {
          log(`Unknown label ${instruction.label}`, instruction.lineNumber);

          return;
        }

        opcode = buildOpcode(
          instruction.opcodeString,
          instruction.bitCount,
          label.address
        );
        break;
      }
      case "constant": {
        if (instruction.subtype === "literal") {
          opcode = instruction.value;
        } else {
          // Label
          const label = matchedLabels[instruction.label];

          if (!label) {
            log(`Unknown label ${instruction.label}`, instruction.lineNumber);

            return;
          }

          console.log(`${label.address.toString(16)}`);

          opcode = label.address;
        }
        break;
      }
    }

    const low = opcode & 0xf;
    const mid = (opcode & 0xf0) >> 4;
    const high = (opcode & 0xf00) >> 8;

    const baseAddress = instruction.address * 3;

    threeNibbleBuffer[baseAddress] = high;
    threeNibbleBuffer[baseAddress + 1] = mid;
    threeNibbleBuffer[baseAddress + 2] = low;
  }

  let byteBuffer = 0;
  let bufferAddress = 0;
  let low = false;
  for (let i = 0; i < threeNibbleBuffer.length; i++) {
    const nibble = threeNibbleBuffer[i];

    if (low) {
      byteBuffer |= nibble;

      outputBuffer[bufferAddress] = byteBuffer;

      bufferAddress += 1;
      byteBuffer = 0;
    } else {
      byteBuffer |= nibble << 4;
    }

    low = !low;
  }
};

const readByLines = async (path, onLine) => {
  const rl = readline.createInterface({
    input: fs.createReadStream(path),
    crlfDelay: Infinity,
  });

  let lineNumber = 0;

  rl.on("line", (line) => onLine(line.toLowerCase().trim(), ++lineNumber));

  await events.once(rl, "close");
};

if (argv.length != 4) {
  console.log(`Received ${argv.length - 2} arguments. Expected 2\n`);
  console.log("Usage: node assembler.js [input.asm] [output.bin]");

  process.exit(1);
}

const inputFile = argv[2];
const outputFile = argv[3];

const build = async () => {
  await readByLines(archPath, parseArchLine);

  await readByLines(inputFile, parseAsmLine);

  outputInstructions();

  writeFileSync(outputFile, outputBuffer);
};

build();
