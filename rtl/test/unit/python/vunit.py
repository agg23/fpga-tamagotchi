from os import environ
from vunit.verilog import VUnit
from itertools import product

def run_vunit(test_glob):
  # TODO: This will change based on who is running these tests
  #$env:VUNIT_MODELSIM_PATH = 'C:/intelFPGA_lite/17.0/modelsim_ase/win32aloem/'
  environ["VUNIT_MODELSIM_PATH"] = "C:/intelFPGA_lite/17.0/modelsim_ase/win32aloem/"

  vu = VUnit.from_argv()

  # Create library 'lib'
  lib = vu.add_library("lib")

  # Add all RTL
  # Last group adds fake Intel specific IP
  lib.add_source_files(["../../*.sv", "../../core/*.sv", "../../test/libraries/*.sv"], allow_empty=True)

  # Add all TBs
  lib.add_source_files(test_glob)
  # Supporting files
  lib.add_source_files("util/*.sv")

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

      elif test.name.startswith("GENrd"):
        # Add configs for decimal and r 0-3
        for r in range(4):
          test.add_config("d 0 r %x" % (r), generics=dict(decimal=0, r=r))
          test.add_config("d 1 r %x" % (r), generics=dict(decimal=1, r=r))

      elif test.name.startswith("GENr"):
        # Add configs for r 0-3
        for r in range(4):
          test.add_config("r %x" % (r), generics=dict(r=r))

      elif test.name.startswith("GENip"):
        # Add configs for i, p 0-15
        for (i, p) in product(range(16), range(16)):
          test.add_config("i %x p %x" % (i, p), generics=dict(i=i, p=p))

      elif test.name.startswith("GENi"):
        # Add configs for i 0-15
        for i in range(16):
          test.add_config("i %x" % (i), generics=dict(i=i))

  # Run vunit function
  vu.main()