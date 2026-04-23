# Pull Request Summary: Pipelined Cache Integration & Benchmarking

## Overview
This PR finalizes the integration of the **Pipelined Cached Computer** into the unified ECE 251 template. It introduces hierarchical memory simulation, allowing students to explore the "Memory Wall" and the performance impact of various caching strategies.

## Key Changes

### 1. Architectural Upgrade
- **L1 Cache Controllers**: Added `cache_direct_mapped.sv`, `cache_set_associative.sv`, and `cache_fully_associative.sv`.
- **Memory Handshaking**: Updated the system bus to handle asynchronous `dmem_ready` signals and `mem_stall` back-pressure.
- **Hierarchy Diagram**: Created a Mermaid visualization in `ARCHITECTURE.md` showing the DP <-> L1 <-> DRAM relationship.

### 2. Performance Telemetry
- **Hardware Counters**: Modified `tb_computer.sv` to count clock cycles, retired instructions, and cache hits/misses.
- **Automated CPI Calculation**: The simulation now prints an "Effective CPI" summary upon program termination.
- **loop_test.asm**: Added a benchmark program specifically designed to demonstrate temporal and spatial locality.

### 3. Documentation
- **Phase 4 (Caches)**: Added a new phase to `MASTER_GUIDE.md` detailing how to optimize performance via memory hierarchy.
- **Benchmarking CLI**: Documented the `+CACHE_EN` argument usage for comparative performance analysis.

## Unimplemented Designs (Reminder for later)
- **Multi-core / SMP support**: Coordinating multiple CPU caches (Cache Coherency protocols).
- **Virtual Memory / TLB**: Address translation before the L1 cache lookup.
- **Write-Back vs Write-Through**: Currently, the models focus on read-hit logic; sophisticated write policies are future extensions.
- **Advanced Branch Prediction**: Implementing BTB or Gshare to reduce pipeline bubbles.
