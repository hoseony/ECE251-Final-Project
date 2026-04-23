# GEMINI.md - Pipelined MIPS32 CPU with Exceptions

This document provides instructional context for the ECE 251 Pipelined MIPS32 Processor project, focusing on the implementation of exceptions and interrupts.

## Project Overview
A 5-stage MIPS32 Pipelined Processor implemented in SystemVerilog. Derived from Patterson & Hennessy (6th Ed), this implementation specifically adds support for **Asynchronous Pipeline Exceptions** and **External Interrupts**.

- **Tech Stack**: SystemVerilog, Python (Assembler), Icarus Verilog (`iverilog`), `vvp`, `gtkwave`/`surfer` (VCD visualization).
- **Architecture**: 5-stage pipeline (IF, ID, EX, MEM, WB).
- **Special Features**: 
  - Asynchronous interrupt pin (`intr`) triggers pipeline flushes and PC redirection.
  - Exception vector located at `32'h8000_0180`.
  - Hazard detection and data forwarding for RAW hazards and control hazards.

## Pipeline Architecture
1.  **IF (Instruction Fetch)**: Fetches from `imem`, increments PC. Redirection occurs here on branch/jump/exception.
2.  **ID (Instruction Decode)**: Reads `regfile`, resolves branches (using `eqcmp`), sign-extends immediates. Hazard unit triggers stalls/flushes here.
3.  **EX (Execute)**: ALU operations, address calculation, data forwarding via muxes. Captures `EPC` on exception.
4.  **MEM (Memory)**: Data memory (`dmem`) read/write.
5.  **WB (Writeback)**: Result written to `regfile` on negative clock edge.

## Building and Running
The project uses a `Makefile` to automate the assembly and simulation workflow.

- **Standard Run**: 
  ```bash
  make all ASM=test_prog
  ```
- **Interrupt Test**: 
  ```bash
  make all ASM=test_exceptions
  ```
- **Clean Artifacts**:
  ```bash
  make clean
  ```
- **Manual Assembly**:
  ```bash
  python3 assembler.py <input.asm> <output.exe>
  ```

## Development Conventions
- **Memory-Mapped I/O Halt**: Write to address `252` (`0xFC`) to gracefully terminate the simulation.
  ```assembly
  sw $zero, 252($zero)
  ```
- **Assembler**: Supports `.org` for memory placement and basic MIPS instructions (`add`, `sub`, `and`, `or`, `slt`, `mult`, `mfhi`, `mflo`, `lw`, `sw`, `beq`, `addi`, `j`).
- **Debugging**: Simulation logs cycle-by-cycle state to `debug_output.txt`.

## Known Issues & Architectural Flaws
The following critical issues were identified and documented in `TODO.md`. **Prioritize fixing these before production or deep feature work.**

1.  **EPC Logic Error**: `datapath.sv` captures the PC of the instruction in EX instead of the one being flushed in ID. This causes instruction re-execution/skipping bugs.
2.  **ALU Control Collisions**: `alucontrol` (3 bits) is overloaded. `mfhi` and `div` both use `3'b101`, and `mult` and `nor` both use `3'b011`.
3.  **Exception Vector Aliasing**: Shallow `imem` depth causes `0x180` to alias to `0x80`.
4.  **Testbench Port Mismatch**: `tb_computer.sv` is missing the `intr` port instantiation.

## File Structure
- `cpu.sv`: Top-level CPU wrapper.
- `datapath.sv`: Pipelined datapath implementation.
- `hazard.sv`: Hazard unit (forwarding, stalls, flushes).
- `controller.sv`: Main and ALU decoders.
- `imem.sv` / `dmem.sv`: Instruction and Data memory.
- `assembler.py`: Python script to convert `.asm` to `.exe` (hex format for `$readmemh`).
- `tb_computer.sv`: Main system testbench.
- `tb_exceptions.sv`: Specialized testbench for interrupt verification.
