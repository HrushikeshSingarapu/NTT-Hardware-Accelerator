import subprocess
import random
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from ntt_reference import ntt

Q = 3329

# ── STEP 1: generate random input polynomial ──
random.seed(42)
input_poly = [random.randint(0, Q-1) for _ in range(256)]

# ── STEP 2: write input to file for Verilog ──
os.makedirs("sim_output", exist_ok=True)
with open("sim_output/input.txt", "w") as f:
    for val in input_poly:
        f.write(f"{val}\n")
print("Input written to sim_output/input.txt")

# ── STEP 3: compile and run Verilog simulation ──
print("Compiling Verilog...")
compile_cmd = [
    "iverilog", "-g2012", "-o", "sim_output/top.out",
    "rtl/mod_adder.sv", "rtl/mod_subtractor.sv", "rtl/mod_multiplier.sv",
    "rtl/butterfly.sv", "rtl/twiddle_rom.sv", "rtl/poly_mem.sv",
    "rtl/addr_gen.sv", "rtl/ntt_controller.sv", "rtl/ntt_top.sv",
    "tb/tb_ntt_top.sv"
]
result = subprocess.run(compile_cmd, capture_output=True, text=True)
if result.returncode != 0:
    print("Compile error:")
    print(result.stderr)
    sys.exit(1)
print("Compile OK.")

print("Running simulation...")
result = subprocess.run(["vvp", "sim_output/top.out"],
                        capture_output=True, text=True)
print(result.stdout)
if result.returncode != 0:
    print("Simulation error:")
    print(result.stderr)
    sys.exit(1)

# ── STEP 4: read Verilog output ──
with open("sim_output/ntt_out.txt", "r") as f:
    verilog_output = [int(line.strip()) for line in f.readlines()]

# ── STEP 5: compute Python golden output ──
expected = ntt(input_poly)

# ── STEP 6: compare ──
print("\n── Verification ──")
mismatches = 0
for i in range(256):
    if verilog_output[i] != expected[i]:
        print(f"MISMATCH at [{i}]: Verilog={verilog_output[i]}, Expected={expected[i]}")
        mismatches += 1

if mismatches == 0:
    print("PASS — Verilog output matches Python golden model exactly.")
else:
    print(f"FAIL — {mismatches} mismatches out of 256 coefficients.")