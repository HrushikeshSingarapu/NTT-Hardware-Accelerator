import subprocess
import random
import os
import sys

# Kyber Parameters
Q = 3329
ZETA = 17

def br7(x):
    result = 0
    for _ in range(7):
        result = (result << 1) | (x & 1)
        x >>= 1
    return result

def ntt_reference(poly):
    # Kyber-specific bit-reversed twiddle factors
    twiddles = [pow(ZETA, br7(i), Q) for i in range(128)]
    a = poly.copy()
    k = 1
    length = 128
    while length >= 2:
        for start in range(0, 256, 2 * length):
            z = twiddles[k]; k += 1
            for j in range(start, start + length):
                t = (z * a[j + length]) % Q
                a[j + length] = (a[j] - t) % Q
                a[j] = (a[j] + t) % Q
        length >>= 1
    return a

# --- Setup and Simulation Execution ---
os.makedirs("sim_output", exist_ok=True)
random.seed(42) # Set seed for repeatability
input_poly = [random.randint(0, Q-1) for _ in range(256)]

with open("sim_output/input.txt", "w") as f:
    for val in input_poly:
        f.write(f"{val}\n")

print("Compiling and Running Verilog Simulation...")
# Assuming your compile/run shell command is standard
subprocess.run(["iverilog", "-g2012", "-o", "sim_output/top.out", 
                "rtl/mod_adder.sv", "rtl/mod_subtractor.sv", "rtl/mod_multiplier.sv",
                "rtl/butterfly.sv", "rtl/twiddle_rom.sv", "rtl/poly_mem.sv",
                "rtl/ntt_controller.sv", "rtl/ntt_top.sv", "tb/tb_ntt_top.sv"])
subprocess.run(["vvp", "sim_output/top.out"])

# --- Verification Logic ---
with open("sim_output/ntt_out.txt", "r") as f:
    verilog_output = []
    for line in f:
        v = line.strip()
        if not v or 'x' in v.lower() or 'z' in v.lower():
            verilog_output.append(-1)
        else:
            verilog_output.append(int(v))

expected = ntt_reference(input_poly)

print("\n── NTT Side-by-Side Verification ──")
mismatches = 0
for i in range(256):
    if i < len(verilog_output):
        actual = verilog_output[i]
        exp = expected[i]
        
        if actual != exp:
            # Matches your screenshot format exactly
            print(f"MISMATCH at [{i:3}]: Verilog={actual if actual != -1 else 'X'}, Expected={exp}")
            mismatches += 1
    else:
        print(f"MISSING DATA at [{i:3}]")
        mismatches += 1

print("\n── FINAL REPORT ──")
if mismatches == 0:
    print("PASS — Hardware matches Python model exactly (256/256).")
else:
    print(f"FAIL — {mismatches} mismatches out of 256 coefficients.")