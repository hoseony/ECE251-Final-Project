# MIPS Project Layout & Conventions

This project is a multi-architecture template for MIPS32 design.

## Core Mandates
- **Include Guards**: Every `.sv` file MUST use `` `ifndef MODULE_NAME `` guards.
- **ALU Control Standard**: All implementations MUST use the 4-bit standard:
    - `4'b0000`: AND
    - `4'b0001`: OR
    - `4'b0010`: ADD
    - `4'b0011`: NOR
    - `4'b0100`: MFLO
    - `4'b0101`: MFHI
    - `4'b0110`: SUB
    - `4'b0111`: SLT
    - `4'b1000`: MULT
    - `4'b1001`: DIV
- **Register 0**: Register `$zero` ($0) MUST be hardwired to 0 and writes to it MUST be suppressed.

## Implementation Guide
- **Single-Cycle**: Reference `single_cycle_computer/`. Good for debugging basic logic.
- **Multi-Cycle**: Reference `multi_cycle_computer/`. Focuses on Finite State Machines (FSM).
- **Pipelined**: Reference `pipelined_computer/`. Focuses on concurrency and hazards.

## Tooling Usage
The Python assembler in `tools/` is the source of truth for instruction encodings. Use it to compile programs into the `programs/` directory.

```bash
python3 tools/assembler.py programs/my_code.asm programs/my_code.exe
```
