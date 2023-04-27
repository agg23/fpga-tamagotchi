import { execSync } from "child_process";

const commands = [
  {
    command:
      "node micro_asm.js ../rtl/core/rom/microcode.asm ../rtl/core/rom/microcode.rom",
    error: "Failed to build microcode",
  },
  {
    command:
      "node modelsim.js ../rtl/core/rom/microcode.rom ../rtl/core/rom/microcode.hex 4",
    error: "Failed to create ModelSim microcode binary",
  },
];

for (const { command, error } of commands) {
  const stdout = execSync(command);

  if (stdout.length > 0) {
    console.log(stdout.toString());
    console.log(error);

    break;
  }
}
