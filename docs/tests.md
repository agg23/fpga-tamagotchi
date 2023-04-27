# Tests

In order to aid in development and ensure the design stuck to the specifications, several levels of tests were built:

* Handwritten validation tests - The root `/rtl/test/` folder - Very basic functionality
* Unit tests - `/rtl/test/unit/` - Every instruction and major CPU operation tested for full functionality and around edgecases
* Verilator - `/rtl/test/verilator/` - Fast iteration and full simulation of the entire project

## Handwritten Validation Tests

These tests were created when I was just starting, and don't use any framework or methodology besides ModelSim. They contain hardcoded paths due to ModelSim being a pain, and likely are out of date/will fail, as they haven't been run since most of the unit tests were built.

This tests can be run by adding them to a ModelSim project and clicking "Simulate".

## Unit Tests

Unit tests use [VUnit](https://github.com/VUnit/vunit), a Python framework for integrating with a simulator for the purposes of building unit tests. It has some strange issues (like being unable to put commas in test names), but generally lets me write unit tests like you would for software.

In `/rtl/test/unit/python/vunit.py` I set up the base unit testing structure, and define the `"GEN"` test types. Tests prefixed with "GEN" are multiplied to have various conditions changed. For example, `GENr` will run the test for `r = 0-3`. This is used to have more complete coverage, though due to execution time, we do not try all possible inputs for many instructions.

First set your `VUNIT_MODELSIM_PATH` in `/rtl/test/unit/python/vunit.py`, so that it points to your ModelSim installation.

Then tests can be run by running:

```python
python run_instructions.py
python run_cpu_top.py
```

## Verilator

Verilator is being used through a Rust project, and should be able to be run with `cargo run`. Small code edits will allow you to turn on tracing, though the code is messy and could be cleaned up.

There is some disagreement between ModelSim and Verilator about how the video BRAM should be implemented without registered outputs. I ended up just passing a `SIM_TYPE` parameter to the video RAM, that differs for ModelSim and Verilator.

## Problems

All of the hardcoded assets that populate ROMs (such as the microcode ROM) have issues with the `readmemh` paths. ModelSim handles the paths differently from Quartus, who handles it differently than Verilator. Because of this, the paths are chosen to work for Quartus, and must be manually updated for ModelSim/Verilator. If you have a way to improve this, please let me know.

Several early tests also have hardcoded complete paths. Those also need to be manually updated if you want to run those tests.