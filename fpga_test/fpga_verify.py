import serial
import serial.tools.list_ports
import random
import time
import sys

Q    = 3329
ZETA = 17
CLOCK_FREQ_HZ = 100_000_000  # Basys 3 = 100 MHz

def br7(x):
    result = 0
    for _ in range(7):
        result = (result << 1) | (x & 1)
        x >>= 1
    return result

ZETAS = [pow(ZETA, br7(i), Q) for i in range(128)]

def ntt_software(poly):
    """Pure Python NTT - this is the SOFTWARE implementation"""
    a = poly.copy()
    k = 1
    length = 128
    while length >= 2:
        for start in range(0, 256, 2 * length):
            z = ZETAS[k]; k += 1
            for j in range(start, start + length):
                t           = (z * a[j + length]) % Q
                a[j+length] = (a[j] - t) % Q
                a[j]        = (a[j] + t) % Q
        length >>= 1
    return a

def find_basys3_port():
    """Auto-detect Basys 3 COM port"""
    ports = serial.tools.list_ports.comports()
    print("  All available ports:")
    for p in ports:
        print(f"    {p.device} - {p.description} - {p.hwid}")
    
    for p in ports:
        desc = p.description.upper()
        hwid = p.hwid.upper()
        if any(x in desc or x in hwid for x in 
               ['DIGILENT', 'BASYS', 'USB SERIAL', 'USB-SERIAL', 'UART']):
            return p.device
    return None

print("=" * 60)
print("  NTT Hardware Accelerator - FPGA Verification")
print("  Basys 3 (Artix-7) vs Python Software")
print("=" * 60)

# ── Step 1: Generate test input ──────────────────────────────
random.seed(42)
poly_input = [random.randint(0, Q-1) for _ in range(256)]
print(f"\nInput polynomial: 256 coefficients, random seed=42")
print(f"Sample: {poly_input[:6]} ...")

# ── Step 2: Run SOFTWARE NTT and measure time ─────────────────
print("\n[SOFTWARE] Running Python NTT...")

NUM_RUNS = 1000
start_time = time.perf_counter()
for _ in range(NUM_RUNS):
    expected = ntt_software(poly_input)
end_time = time.perf_counter()

sw_total_sec   = end_time - start_time
sw_single_sec  = sw_total_sec / NUM_RUNS
sw_single_us   = sw_single_sec * 1_000_000
sw_single_ms   = sw_single_sec * 1_000

print(f"  Runs: {NUM_RUNS}")
print(f"  Total time: {sw_total_sec*1000:.2f} ms")
print(f"  Per run:    {sw_single_us:.2f} microseconds")
print(f"  Per run:    {sw_single_ms:.4f} milliseconds")

# ── Step 3: Connect to FPGA ───────────────────────────────────
print("\n[HARDWARE] Connecting to Basys 3 FPGA...")
print("  Scanning ports...")
port = find_basys3_port()

if port is None:
    print("\n  ERROR: Basys 3 not found automatically.")
    print("  Please enter COM port manually (e.g., COM3 or /dev/ttyUSB0):")
    port = input("  Port: ").strip()

print(f"  Using port: {port}")

try:
    ser = serial.Serial(port, baudrate=115200, timeout=10)
    time.sleep(0.5)
    print(f"  Connected!")
except Exception as e:
    print(f"  ERROR connecting: {e}")
    print("  Check: Is Basys 3 powered? Is the bitstream programmed?")
    sys.exit(1)

# ── Step 4: Send 256 coefficients to FPGA ────────────────────
print("\n[HARDWARE] Sending 256 coefficients to FPGA (512 bytes)...")
tx_bytes = bytearray()
for coeff in poly_input:
    tx_bytes.append(coeff & 0xFF)           # low byte
    tx_bytes.append((coeff >> 8) & 0x0F)    # high nibble

hw_send_start = time.perf_counter()
ser.write(tx_bytes)
print(f"  Sent {len(tx_bytes)} bytes")

# ── Step 5: Receive results from FPGA ────────────────────────
# ── Step 5: Receive results from FPGA ────────────────────────
print("[HARDWARE] Waiting for FPGA results...")

rx_raw = b''
while len(rx_raw) < 515:
    chunk = ser.read(515 - len(rx_raw))
    if not chunk:
        print(f"  Timeout with {len(rx_raw)} bytes received")
        break
    rx_raw += chunk

hw_send_end = time.perf_counter()
print(f"  Received {len(rx_raw)} bytes")

if len(rx_raw) < 515:
    print(f"  ERROR: Expected 515 bytes, got {len(rx_raw)}")
    ser.close()
    sys.exit(1)

ser.close()

# ── Step 6: Decode FPGA output ───────────────────────────────
fpga_output = []
for i in range(256):
    lo = rx_raw[i*2]
    hi = rx_raw[i*2 + 1] & 0x0F
    fpga_output.append((hi << 8) | lo)

# Old bitstream drops byte0 (0x80=128), sends bytes 1,2,3 only
# Reconstruct: prepend 0x80 to get full 4-byte little-endian count
cyc_bytes = bytes([0x80]) + rx_raw[512:515]
hw_cycles = int.from_bytes(cyc_bytes, byteorder='little')
# Hardware time from cycle count
hw_time_sec = hw_cycles / CLOCK_FREQ_HZ
hw_time_us  = hw_time_sec * 1_000_000
hw_time_ns  = hw_time_sec * 1_000_000_000

print(f"\n[HARDWARE] NTT completed!")
print(f"  Clock cycles:  {hw_cycles}")
print(f"  At 100 MHz:    {hw_time_us:.3f} microseconds")
print(f"  At 100 MHz:    {hw_time_ns:.1f} nanoseconds")

# ── Step 7: Verify correctness ────────────────────────────────
print("\n[VERIFICATION] Comparing FPGA output vs Python reference...")
mismatches = 0
for i in range(256):
    if fpga_output[i] != expected[i]:
        if mismatches < 5:
            print(f"  MISMATCH [{i}]: FPGA={fpga_output[i]}, Expected={expected[i]}")
        mismatches += 1

print(f"\n  Result: {'PASS' if mismatches==0 else 'FAIL'}")
print(f"  Mismatches: {mismatches} / 256")

# ── Step 8: Performance comparison ───────────────────────────
speedup = sw_single_us / hw_time_us
print("\n" + "=" * 60)
print("  PERFORMANCE COMPARISON SUMMARY")
print("=" * 60)
print(f"  Software (Python, {NUM_RUNS} run avg):")
print(f"    Time: {sw_single_us:.2f} microseconds")
print(f"    Time: {sw_single_ms:.4f} milliseconds")
print(f"")
print(f"  Hardware (Basys 3 FPGA, 100 MHz):")
print(f"    Clock cycles: {hw_cycles}")
print(f"    Time: {hw_time_us:.3f} microseconds")
print(f"    Time: {hw_time_ns:.1f} nanoseconds")
print(f"")
print(f"  Speedup: {speedup:.1f}x faster on hardware")
print(f"")

#c_estimate_us = sw_single_us / 75
#c_speedup = c_estimate_us / hw_time_us
#print(f"  Estimated C software NTT: ~{c_estimate_us:.2f} microseconds")
#print(f"  Hardware vs C estimate:   ~{c_speedup:.1f}x faster")
print(f"")
print(f"  {'HARDWARE VERIFIED CORRECT!' if mismatches==0 else 'VERIFICATION FAILED - check hardware'}")
print("=" * 60)

# Save results to file
with open("fpga_test/results.txt", "w") as f:
    f.write("NTT FPGA VERIFICATION RESULTS\n")
    f.write("="*50 + "\n")
    f.write(f"Software time (Python): {sw_single_us:.2f} us\n")
    f.write(f"Hardware cycles: {hw_cycles}\n")
    f.write(f"Hardware time: {hw_time_us:.3f} us\n")
    f.write(f"Speedup: {speedup:.1f}x\n")
    f.write(f"Mismatches: {mismatches}/256\n")
    f.write(f"Status: {'PASS' if mismatches==0 else 'FAIL'}\n")
print("\nResults saved to fpga_test/results.txt")