from vunit.verilog import VUnit

#$env:VUNIT_MODELSIM_PATH = 'C:/intelFPGA_lite/17.0/modelsim_ase/win32aloem/'

# Create VUnit instance by parsing command line arguments
vu = VUnit.from_argv()

# Create library 'lib'
lib = vu.add_library("lib")

# Add all RTL
lib.add_source_files("../*.sv")

# Add all TBs
lib.add_source_files("instructions/*.sv")
# Supporting files
lib.add_source_files("instructions/util/*.sv")

# Run vunit function
vu.main()