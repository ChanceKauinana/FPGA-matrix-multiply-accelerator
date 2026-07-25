# SystemVerilog Matrix Multiply Accelerator

This project implements a small FPGA-oriented matrix multiplication accelerator in SystemVerilog. The design is built in stages, starting from a signed multiply-accumulate unit, expanding into a dot-product engine, and then building a fixed 2x2 matrix multiplication engine.

The project focuses on RTL design, signed arithmetic, finite state machine control, modular datapath design, and verification using both SystemVerilog testbenches and a Python golden model.

## Current Status

The project currently includes:

- Signed MAC unit
- Dot-product engine using the MAC unit
- 2x2 matrix multiply engine
- Self-checking SystemVerilog testbenches
- Directed positive and signed test cases
- Python golden model
- Randomized signed test-vector generation
- SystemVerilog testbench comparison against Python-generated expected outputs
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
rtl/malmult_2x2_engine.sv
sim/tb_malmult_2x2_engine.sv
```

Status:

```text
Simulation: Passed
Positive test case: Passed
Signed test case: Passed
```

### Stage 4: Python Golden Model and Randomized Verification

A Python golden model generates directed and randomized signed 2x2 matrix multiplication test vectors.

The SystemVerilog testbench reads the generated vector file, drives the RTL inputs, waits for the DUT result, and compares the hardware output against the Python-computed expected result.

Implemented files:

```text
model/matmul_model.py
sim/matmul_2x2_vectors.txt
sim/tb_malmult_2x2_engine.sv
```

The generated vector file contains:

```text
a00 a01 a10 a11 b00 b01 b10 b11 expected_c00 expected_c01 expected_c10 expected_c11
```

Current verification includes:

```text
Directed positive test cases
Directed signed test cases
100 randomized signed 8-bit matrix test cases
Automatic pass/fail checking in the SystemVerilog testbench
```

Status:

```text
Python golden model: Passed
Randomized vector generation: Passed
RTL comparison against Python expected outputs: Passed
```

## Verification

Each hardware module includes a self-checking SystemVerilog testbench.

The testbenches verify:

- Reset behavior
- Start/done handshaking
- Valid input behavior
- Signed arithmetic
- Directed test cases
- Randomized test cases
- Expected-output comparison
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

The Python golden model also generates randomized signed 8-bit matrices and computes the expected 32-bit accumulated outputs.

## Repository Structure

```text
rtl/
  mac_unit.sv
  dot_product_engine.sv
  malmult_2x2_engine.sv

sim/
  tb_mac_unit.sv
  tb_dot_product_engine.sv
  tb_malmult_2x2_engine.sv
  matmul_2x2_vectors.txt

model/
  matmul_model.py

constraints/
  Basys-3-Master.xdc

README.md
.gitignore
```

## Tools

- SystemVerilog
- Python
- Xilinx Vivado
- XSim Simulator
- Basys 3 FPGA
- Artix-7 FPGA fabric

## Roadmap

- [x] Stage 1: Signed MAC unit
- [x] Stage 2: Dot-product engine
- [x] Stage 3: 2x2 matrix multiply engine
- [x] Stage 4: Python golden model
- [x] Stage 5: Randomized RTL verification
- [ ] Stage 6: Synthesis and timing report
- [ ] Optional: UART interface for terminal-based input/output
- [ ] Optional: 4x4 matrix multiply engine

## Future Improvements

Possible future additions include:

- Vivado synthesis report
- LUT, FF, and DSP utilization table
- Timing report and maximum frequency estimate
- Waveform screenshots in the README
- Architecture diagram
- 4x4 matrix multiplication support
- Pipelined datapath
- UART interface for sending matrix inputs from a PC terminal
- Basys 3 hardware demo for the full matrix multiply engine

## Project Goal

The goal of this project is to develop a small but realistic FPGA compute accelerator using clean RTL design practices, modular datapath/control design, and self-checking verification.

This project demonstrates:

- Signed arithmetic in hardware
- Multiply-accumulate datapath design
- Dot-product computation
- Matrix multiplication
- FSM-based control logic
- SystemVerilog testbench development
- Python golden model verification
- Randomized test-vector generation
- FPGA implementation workflow