# MIPS CPU Architecture Project Template

This repository is a comprehensive pedagogical resource for the **ECE 251 Computer Architecture** course at **The Cooper Union**. It provides a complete, modular, and standardized template for students to explore, build, and extend various CPU architectures.

## Project Structure

The repository is organized into three distinct architectural implementations of the MIPS32 RISC instruction set, along with centralized tooling and software.

### 1. [Single-Cycle Computer](./single_cycle_computer/)
A fundamental implementation where each instruction executes in exactly one clock cycle. This serves as the baseline for understanding data movement and control signals.

### 2. [Multi-Cycle Computer](./multi_cycle_computer/)
An implementation that breaks instruction execution into multiple steps (Fetch, Decode, Execute, Memory, Writeback), sharing hardware resources like the ALU and Memory across cycles.

### 3. [Pipelined Computer](./pipelined_computer/)
An advanced 5-stage pipelined processor (IF, ID, EX, MEM, WB) featuring:
- **Hazard Detection & Forwarding**: Resolves data and control hazards to maintain throughput.
- **Exceptions & Interrupts**: Support for asynchronous hardware interrupts and internal exceptions.

### 4. [Pipelined Cached Computer](./pipelined_cached_computer/)
Extends the pipelined model with **Hierarchical Memory**:
- **Cache Controller**: Supports Direct-Mapped, Set-Associative, and Fully-Associative configurations.
- **Memory Wall Analysis**: Demonstrates the impact of 10-cycle main memory latency vs. 1-cycle cache hits.
- **Performance Telemetry**: Integrated cycle counters, hit/miss tracking, and CPI calculation.

### 5. [Programs](./programs/)
A centralized folder for MIPS assembly (`.asm`) source files and their compiled machine code equivalents (`.exe` / `.dat`). Since the ISA is identical across all architectures, programs can be shared.

### 6. [Tools](./tools/)
Centralized Python scripts for development:
- `assembler.py`: Translates MIPS assembly into machine code hex format.
- `patch.py`: Utility for patching or verifying machine code.

## Getting Started

Students should refer to the **[MASTER_GUIDE.md](./MASTER_GUIDE.md)** for a detailed phase-by-phase walkthrough of building these systems.

### Prerequisites
- **Icarus Verilog** (`iverilog`)
- **VVP** (runtime)
- **GTKWave** (waveform viewer)
- **Python 3** (for tooling)

### Building and Running
Each computer directory contains a `Makefile`.

```bash
# Example: Running the pipelined computer
cd pipelined_computer/
make all ASM=test_prog
```

## Release Information
- **Current Version**: v1.0.1
- **Architecture Standard**: MIPS32-compatible with 4-bit ALU Control.
- **Register File**: Standard 32-register GPR file (Register 0 hardwired to 0).
