import subprocess
import random
import os
import sys
import time

Q = 3329
ZETA = 17

def br7(x):
    result = 0
    for _ in range(7):
        result = (result << 1) | (x & 1)
        x >>= 1
    return result

ZETAS = [pow(ZETA, br7(i), Q) for i in range(128)]

def ntt_reference(poly):
    a = poly.copy()
    k = 1; length = 128
    while length >= 2:
        for start in range(0, 256, 2 * length):
            z = ZETAS[k]; k += 1
            for j in range(start, start + length):
                t           = (z * a[j + length]) % Q
                a[j + length] = (a[j] - t) % Q
                a[j]          = (a[j] + t) % Q
        length >>= 1
    return a

os.makedirs("sim_output", exist_ok=True)
random.seed(42)
input_poly = [random.randint(0, Q-1) for _ in range(256)]

with open("sim_output/input.txt", "w") as f:
    for val in input_poly:
        f.write(f"{val}\n")
print("Input written to sim_output/input.txt")

# Measure software NTT time
NUM_RUNS = 1000
print(f"Measuring software NTT time ({NUM_RUNS} runs)...")
t_start = time.perf_counter()
for _ in range(NUM_RUNS):
    expected = ntt_reference(input_poly)
t_end = time.perf_counter()

sw_us = (t_end - t_start) / NUM_RUNS * 1_000_000
print(f"Software NTT average time: {sw_us:.2f} microseconds")

print("Compiling Verilog...")
compile_cmd = [
    "iverilog", "-g2012", "-o", "sim_output/top.out",
    "rtl/mod_adder.sv", "rtl/mod_subtractor.sv", "rtl/mod_multiplier.sv",
    "rtl/butterfly.sv", "rtl/twiddle_rom.sv", "rtl/poly_mem.sv",
    "rtl/ntt_controller.sv", "rtl/ntt_top.sv",
    "tb/tb_ntt_top.sv"
]
result = subprocess.run(compile_cmd, capture_output=True, text=True)
if result.returncode != 0:
    print("Compile FAILED:"); print(result.stderr); sys.exit(1)
print("Compile OK.")

print("Running simulation...")
result = subprocess.run(["vvp", "sim_output/top.out"], capture_output=True, text=True)
print(result.stdout)

with open("sim_output/ntt_out.txt", "r") as f:
    lines = f.readlines()

verilog_output = []
for line in lines:
    v = line.strip()
    if not v or 'x' in v.lower() or 'z' in v.lower():
        verilog_output.append(-1)
    else:
        verilog_output.append(int(v))

print("\n── Verification ──")
mismatches = 0
for i in range(256):
    if i >= len(verilog_output):
        mismatches += 1
    elif verilog_output[i] == -1:
        print(f"X/Z at [{i}]"); mismatches += 1
    elif verilog_output[i] != expected[i]:
        if mismatches < 5:
            print(f"MISMATCH [{i}]: Verilog={verilog_output[i]}, Expected={expected[i]}")
        mismatches += 1

# Simulation timing (from simulation output if available)
HW_CYCLES_SIM = 2692  # from your simulation output "after 2692 cycles"
HW_FREQ_HZ    = 100_000_000
hw_us_sim     = HW_CYCLES_SIM / HW_FREQ_HZ * 1_000_000

print(f"\n── Performance Summary ──")
print(f"Software NTT (Python):     {sw_us:.2f} us")
print(f"Hardware NTT (simulation): {HW_CYCLES_SIM} cycles = {hw_us_sim:.3f} us @ 100MHz")
print(f"Speedup (Python vs HW):    {sw_us/hw_us_sim:.1f}x")
print(f"Verification: {'PASS' if mismatches==0 else 'FAIL'} ({mismatches}/256 mismatches)")