# Changelog

All notable changes to this project will be documented in this file.

## [1.0.2] - 2026-04-23
### Added
- **Pipelined Cached Computer**: Full integration of L1 Cache Controllers (Direct, Set, Fully Associative).
- **Memory Latency Simulation**: `dmem.sv` now supports multi-cycle latency with a `dmem_ready` handshake.
- **Performance Benchmarking**: Integrated telemetry into testbenches to track CPI, Hits, and Misses.
- **Cache Architecture Diagrams**: Added Mermaid hierarchical diagrams to `ARCHITECTURE.md`.

## [1.0.1] - 2026-04-23
### Added
- **Detailed FSM Documentation**: Enhanced `ARCHITECTURE.md` with cycle-by-cycle FSM state mechanisms for the multi-cycle implementation.
- **Architectural Choice Roadmap**: Updated `MASTER_GUIDE.md` to offer clear Single-Cycle, Multi-Cycle, or Pipelined design paths.

## [1.0.0] - 2026-04-23
### Added
- **Unified MIPS Template**: Released as the official stable template for ECE 251.
- **Multi-Cycle Computer**: Full implementation of a 12-state FSM-based MIPS32 processor.
- **Pipelined Computer**: Advanced 5-stage pipeline with hazard unit and exceptions.
- **Centralized Programs Directory**: Shared `.asm` and `.exe` files for all architectures.
- **Centralized Tools Directory**: Shared Python assembler and patching utilities.
- **MASTER_GUIDE.md**: Structured pedagogical roadmap for students.
- **Include Guards**: `` `ifndef `` guards added to all SV source files.

### Changed
- **Unified Repository Structure**: Reorganized files into architecture-specific folders.
- **4-bit ALU Control**: Standardized all computers to use 4-bit `alucontrol` (0-15) to resolve opcode collisions.
- **Makefiles**: Updated all build scripts to work with the new relative pathing.

### Fixed
- **ALU Control Collisions**: Fixed overlap between `mult`/`nor` and `div`/`mfhi`.
- **Register 0 Protection**: Ensured Register 0 is never modified in any architecture.
- **Testbench Stability**: Corrected array out-of-bounds warnings and clock race conditions.
