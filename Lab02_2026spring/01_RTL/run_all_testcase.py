import os
tests = [ './test0', './test1', './test2', './test3']
# tests = ['./test2', './test3']
for test in tests: 
    os.system(f"cd ../00_TESTBED; cp {test}/* .; cd ../01_RTL; ./01_run_vcs_rtl")

# for test in tests: 
#     os.system(f"cd ../00_TESTBED; cp {test}/* .; cd ../03_GATE; ./01_run_vcs_gate")