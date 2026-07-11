# FPGA Matrix Multiply Accelerator for ML Inference Primitives

This project builds a matrix multiply accelerator in SystemVerilog, starting from a signed multiply-accumulate datapath and expanding toward dot-product and matrix multiplication engines.

## Current Status

Stage 1 complete: signed MAC unit verified in simulation and tested on a Basys 3 FPGA.

## Stage 1: Signed MAC Unit

The MAC unit performs:

```text
result = result + a * b