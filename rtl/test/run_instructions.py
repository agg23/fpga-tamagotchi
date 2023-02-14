from vunit.verilog import VUnit
from itertools import product

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

for bench in lib.get_test_benches(allow_empty=True):
  for test in bench.get_tests():
    if test.name.startswith("GENrqd"):
      # Add configs for decimal and r, q 0-3
      for (r, q) in product(range(4), range(4)):
        test.add_config("d 0 r %x q %x" % (r, q), generics=dict(decimal=0, r=r, q=q))
        test.add_config("d 1 r %x q %x" % (r, q), generics=dict(decimal=1, r=r, q=q))

    elif test.name.startswith("GENrq"):
      # Add configs for r, q 0-3
      for (r, q) in product(range(4), range(4)):
        test.add_config("r %x q %x" % (r, q), generics=dict(r=r, q=q))

# Run vunit function
vu.main()