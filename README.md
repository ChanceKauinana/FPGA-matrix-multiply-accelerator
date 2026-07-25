# SystemVerilog Matrix Multiply Accelerator

This project implements a small FPGA-oriented matrix multiplication accelerator in SystemVerilog. The design is built in stages, starting from a signed multiply-accumulate unit, then expanding into a dot-product engine and a fixed 2x2 matrix multiplication engine.

The long-term goal is to build hardware blocks commonly used in DSP and ML inference workloads, where dot products and matrix multiplication are core operations.

## Current Status

The project currently includes:

- Signed MAC unit
- Dot-product engine using the MAC unit
- 2x2 matrix multiply engine
- Self-checking SystemVerilog testbenches
- Directed positive and signed test cases
- Basys 3 FPGA testing for the MAC unit

## Project Stages

### Stage 1: Signed MAC Unit

The MAC unit performs:

```text
result = result + a * b
```

The block uses signed arithmetic and parameterized widths.

Default configuration:

```text
a, b      : signed 8-bit inputs
product   : signed 16-bit internal product
result    : signed 32-bit accumulator
```

Implemented files:

```text
rtl/mac_unit.sv
sim/tb_mac_unit.sv
```

Status:

```text
Simulation: Passed
Basys 3 FPGA test: Passed
```

### Stage 2: Dot-Product Engine

The dot-product engine computes:

```text
sum = a0*b0 + a1*b1 + ... + aN-1*bN-1
```

This stage adds control logic around the MAC unit, including:

```text
start
valid_in
busy
done
counter
FSM controller
```

Implemented files:

```text
rtl/dot_product_engine.sv
sim/tb_dot_product_engine.sv
```

Status:

```text
Simulation: Passed
Positive test case: Passed
Signed test case: Passed
```

### Stage 3: 2x2 Matrix Multiply Engine

The 2x2 matrix multiply engine computes:

```text
C = A × B
```

For:

```text
A = [ a00  a01 ]
    [ a10  a11 ]

B = [ b00  b01 ]
    [ b10  b11 ]
```

The outputs are:

```text
c00 = a00*b00 + a01*b10
c01 = a00*b01 + a01*b11
c10 = a10*b00 + a11*b10
c11 = a10*b01 + a11*b11
```

Implemented files:

```text
rtl/matmul_2x2_engine.sv
sim/tb_matmul_2x2_engine.sv
```

Status:

```text
Simulation: Passed
Positive test case: Passed
Signed test case: Passed
```

## Verification

Each module includes a self-checking SystemVerilog testbench.

The testbenches verify:

- Reset behavior
- Start/done handshaking
- Signed arithmetic
- Directed test cases
- Expected output comparison
- Pass/fail reporting

Example 2x2 matrix multiply test:

```text
A = [1 2]
    [3 4]

B = [5 6]
    [7 8]

Expected C = [19 22]
             [43 50]
```

## Repository Structure

```text
rtl/
  mac_unit.sv
  dot_product_engine.sv
  matmul_2x2_engine.sv

sim/
  tb_mac_unit.sv
  tb_dot_product_engine.sv
  tb_matmul_2x2_engine.sv

constraints/
  Basys-3-Master.xdc

README.md
.gitignore
```

## Tools

- SystemVerilog
- Xilinx Vivado
- Basys 3 FPGA
- Artix-7 FPGA fabric

## Roadmap

- [x] Stage 1: Signed MAC unit
- [x] Stage 2: Dot-product engine
- [x] Stage 3: 2x2 matrix multiply engine
- [ ] Stage 4: Python golden model
- [ ] Stage 5: Randomized RTL verification
- [ ] Stage 6: Synthesis and timing report
- [ ] Stage 7: UART interface for terminal-based input/output
- [ ] Stage 8: 4x4 matrix multiply engine

## Future Improvements

Possible future additions include:

- Python golden model for automatic expected-output generation
- Randomized signed test cases
- UART interface for sending inputs from a PC terminal
- 4x4 matrix multiplication support
- Pipelined datapath
- DSP slice utilization analysis
- Timing and resource utilization report
- Basys 3 hardware demo for the full matrix multiply engine

## Project Goal

The goal of this project is to develop a small but realistic FPGA compute accelerator using clean RTL design practices, modular datapath/control separation, and self-checking verification.

This project demonstrates:

- Signed arithmetic in hardware
- Multiply-accumulate datapath design
- Dot-product computation
- Matrix multiplication
- FSM-based control logic
- SystemVerilog testbench development
- FPGA implementation workflow