use std::{env, fs, path::PathBuf};

use verilator::{
    gen::{Standard, Verilator},
    module::ModuleGenerator,
};

fn main() {
    let standard_verilog_version = Standard::Verilog2005;
    let system_verilog_version = Standard::SystemVerilog2012;

    // Can't use glob because Verilator wants the imports to be ordered
    let rtl_files = [
        "top.sv",
        "../../core/types.sv",
        "../../core/alu.sv",
        "../../core/decode.sv",
        "../../core/microcode.sv",
        "../../core/reg_mux.sv",
        "../../core/regs.sv",
        "../../core/cpu.sv",
        "../../clock.sv",
        "../../input_lines.sv",
        "../../interrupt.sv",
        "../../prog_timer.sv",
        "../../stopwatch.sv",
        "../../timers.sv",
        "../../video.sv",
        "../libraries/main_ram.sv",
        "../libraries/video_ram.sv",
        "../../cpu_6s46.sv",
    ];

    // This envvar is set by cargo
    let out_dir = env::var("OUT_DIR").unwrap();
    let out_dir = PathBuf::from(out_dir);
    let _ = fs::remove_dir_all(&out_dir);
    fs::create_dir_all(&out_dir).expect("Couldn't create dir");

    // Generate CPP shim from RUST
    let mut module = ModuleGenerator::default();
    module.generate("src/main.rs");

    // Generate CPP from Verilog
    let mut verilator = Verilator::default();
    verilator
        .no_warn("casex")
        .no_warn("width")
        .no_warn("caseincomplete")
        .no_warn("unsigned")
        .with_trace(true);

    for rtl in rtl_files {
        println!("cargo:rerun-if-changed={}", rtl);

        let verilog_version = if rtl.ends_with("sv") {
            system_verilog_version
        } else {
            standard_verilog_version
        };

        verilator.file_with_standard(rtl, verilog_version);
    }

    verilator.file(out_dir.join("top.cpp")).build("top");
}
