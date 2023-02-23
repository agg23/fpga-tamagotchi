import { execSync } from "child_process";

const programs = ["../bass/fib_optimized"];

const commands = [
  {
    command: "node assembler.js program.asm program.rom",
    error: "Failed to build program",
  },
  {
    command: "node modelsim.js program.rom program.hex 3",
    error: "Failed to create ModelSim binary for program",
  },
];

for (const program of programs) {
  for (const { command, error } of commands) {
    const stdout = execSync(command.replace(/program/g, program));

    if (stdout.length > 0) {
      console.log(stdout.toString());
      console.log(error.replace("program", program));

      break;
    }
  }
}
