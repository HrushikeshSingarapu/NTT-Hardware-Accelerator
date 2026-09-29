# NTT Hardware Accelerator for CRYSTALS-Kyber

Configurable RTL-based Number Theoretic Transform (NTT) accelerator for CRYSTALS-Kyber post-quantum cryptography, implemented in SystemVerilog and validated through simulation and FPGA hardware testing.

---

## Overview

The Number Theoretic Transform (NTT) is a core operation used for efficient polynomial multiplication in lattice-based post-quantum cryptography.

This project implements a modular and hierarchical NTT hardware accelerator targeting the CRYSTALS-Kyber cryptosystem.

### Current Implementation

- **NTT size:** 256 coefficients
- **Modulus:** q = 3329
- **Architecture:** Cooley–Tukey NTT
- **NTT stages:** 7
- **Butterfly operations:** 896
- **Clock frequency:** 100 MHz
- **FPGA:** Digilent Basys 3 (Xilinx Artix-7)
- **UART:** 115200 baud

The design combines modular arithmetic, polynomial memory, twiddle-factor ROM, butterfly processing, FSM-based control, and UART communication.

---

## Architecture

```text
                 Host PC
                   │
              UART @ 115200
                   │
          ┌────────▼────────┐
          │   FPGA Top      │
          │   fpga_top.sv   │
          └────────┬────────┘
                   │
          ┌────────▼────────┐
          │    NTT Top      │
          │   ntt_top.sv    │
          └────────┬────────┘
                   │
       ┌───────────┼───────────┐
       │           │           │
       ▼           ▼           ▼
  Controller   Polynomial   Twiddle
  ntt_          Memory       ROM
  controller   poly_mem     twiddle_rom
       │
       ▼
   Butterfly
  butterfly.sv
       │
   ┌───┼───────────┐
   ▼   ▼           ▼
  Add  Multiply   Subtract
```

The accelerator uses a single butterfly processing unit across the NTT computation. The controller sequences the seven NTT stages and 896 butterfly operations.

---

## RTL Modules

| Module | Description |
|---|---|
| `ntt_top.sv` | Top-level NTT accelerator integration |
| `ntt_controller.sv` | FSM-based control and address generation |
| `poly_mem.sv` | Dual-port polynomial coefficient memory |
| `twiddle_rom.sv` | Pre-computed NTT twiddle factors |
| `butterfly.sv` | Core NTT butterfly computation |
| `mod_multiplier.sv` | Modular multiplication |
| `mod_adder.sv` | Modular addition |
| `mod_subtractor.sv` | Modular subtraction |
| `fpga_top.sv` | FPGA-level integration and UART interface |
| `uart_rx.sv` | UART receiver |
| `uart_tx.sv` | UART transmitter |

---

## Processing Flow

1. Polynomial coefficients are received from the host through UART.
2. Input coefficients are stored in polynomial memory.
3. The controller initializes the NTT computation.
4. Twiddle factors are read from the ROM.
5. The butterfly performs modular multiplication, addition, and subtraction.
6. Intermediate results are written back to polynomial memory.
7. The process continues through all seven NTT stages.
8. Final coefficients are read back and transmitted through UART.
9. The output is compared against the Python reference implementation.

---

## Verification

Verification is performed at multiple levels.

### RTL Simulation

The RTL implementation is verified against a Python golden reference model using Icarus Verilog.

```text
Python Golden Model
        │
        ▼
Expected NTT Output
        │
        ├──────────────┐
        │              │
        ▼              ▼
   RTL Simulation   Output Compare
        │              │
        └───────►  0 mismatches
```

The simulation verified all **256 output coefficients** against the Python reference with **0/256 mismatches**.

### FPGA Verification

The design was also validated on a **Digilent Basys 3 FPGA (Xilinx Artix-7)**.

The Python verification script:

- Generates the input polynomial
- Computes the reference NTT
- Sends coefficients to the FPGA through UART
- Receives the FPGA output
- Compares all 256 coefficients
- Reads the hardware cycle count
- Reports the performance comparison

Result:

```text
FPGA Output vs Python Reference

Mismatches: 0 / 256
Result: PASS
```

---

## Performance

For the implemented 256-point NTT:

| Parameter | Result |
|---|---:|
| NTT size | 256 |
| Stages | 7 |
| Butterflies | 896 |
| Cycles / butterfly | 3 |
| Total cycles | **2688** |
| FPGA clock | 100 MHz |
| Hardware execution time | **26.88 µs** |
| FPGA platform | Basys 3 / Artix-7 |
| Verification mismatches | **0 / 256** |

The hardware execution time is deterministic because the NTT computation requires a fixed number of clock cycles for a given configuration.

---

## Python Reference Model

The `python_model` directory contains the software reference used to validate the RTL implementation.

The reference model:

- Implements the 256-point Kyber NTT
- Uses q = 3329
- Generates the required twiddle factors
- Provides the expected output for RTL comparison

---

## FPGA Implementation

The FPGA implementation uses:

- **Board:** Digilent Basys 3
- **FPGA:** Xilinx Artix-7 XC7A35T
- **Clock:** 100 MHz
- **UART:** 115200 baud
- **Tool:** Xilinx Vivado

The `constraints` directory contains the Basys 3 pin constraints.

---

## Repository Structure

```text
NTT-Hardware-Accelerator/
│
├── constraints/
│   └── basys3.xdc
│
├── fpga_test/
│   ├── fpga_verify.py
│   └── results.txt
│
├── python_model/
│   ├── modular_arithmetic.py
│   ├── ntt_reference.py
│   └── verify.py
│
├── rtl/
│   ├── butterfly.sv
│   ├── fpga_top.sv
│   ├── mod_adder.sv
│   ├── mod_multiplier.sv
│   ├── mod_subtractor.sv
│   ├── ntt_controller.sv
│   ├── ntt_top.sv
│   ├── poly_mem.sv
│   ├── twiddle_rom.sv
│   ├── uart_rx.sv
│   └── uart_tx.sv
│
├── sim_output/
│   ├── input.txt
│   └── ntt_out.txt
│
├── tb/
│   └── unit_tests/
│       ├── tb_butterfly.sv
│       ├── tb_controller.sv
│       ├── tb_mod_adder.sv
│       ├── tb_mul.sv
│       ├── tb_poly_mem.sv
│       ├── tb_sub.sv
│       ├── tb_twiddle_rom.sv
│       └── tb_ntt_top.sv
│
├── .gitignore
└── README.md
```

---

## Tools

- SystemVerilog
- Python
- Icarus Verilog
- Xilinx Vivado
- Digilent Basys 3
- Git / GitHub

---

## Project Highlights

- Modular RTL architecture for a 256-point NTT
- FSM-based deterministic control
- Dual-port polynomial memory
- Pre-computed twiddle-factor ROM
- Modular arithmetic datapath
- UART-based FPGA communication
- Python golden-model verification
- Unit-level and system-level verification
- FPGA hardware validation with 0/256 mismatches

---

## Future Work

Potential extensions include:

- Inverse NTT (INTT)
- Pipelined and parallel butterfly architectures
- Further resource and power optimization
- ASIC implementation
- Side-channel resistance techniques
- Extension toward additional post-quantum cryptographic workloads

---

## 👤 Author

**Hrushikesh Singarapu**  
Electronics and Communication Engineering  
Vasavi College of Engineering, Hyderabad

[GitHub](https://github.com/HrushikeshSingarapu) •
[LinkedIn](https://www.linkedin.com/in/hrushikesh-singarapu-22a284291/)
