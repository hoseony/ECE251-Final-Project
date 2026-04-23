# ECE 251 Final Project: Building MIPS CPU Architectures

This guide provides step-by-step instructions on how to build complete MIPS32 processors from scratch, covering Single-Cycle, Multi-Cycle, and Pipelined models. By following these phases, you will implement all components of a classical Von Neumann computer: **CPU, Memory, Datapath, Input, and Output.**

---

## Phase 1: The Foundation (Basic ISA & ALU)
**Goal:** Implement the Arithmetic Logic Unit and basic combinational building blocks.

1.  **Combinational Components:** Start by creating the stateless modules that will drive your datapath.
    *   `adder.sv`: A simple 32-bit behavioral adder.
    *   `mux2.sv`, `mux3.sv`, `mux4.sv`: Multiplexers for path selection.
    *   `sl2.sv`: Shift-left-by-2 for branch address calculation.
    *   `signext.sv`: Sign-extending 16-bit immediates to 32 bits.
    *   `eqcmp.sv`: An equality comparator for branch resolution in the Decode stage.
2.  **The ALU (`alu.sv`):** Build a 32-bit ALU that supports:
    *   `AND`, `OR`, `ADD`, `NOR`, `SUB`, `SLT`.
    *   **Sequential Logic:** Multi-cycle multiplication (`MULT`) and division (`DIV`) results stored in a 64-bit `HiLo` register on the `negedge clk`.
    *   **Control Mapping:** Use a **4-bit `alucontrol`** signal to avoid collisions between instructions (e.g., `mult` vs `nor`).
3.  **ALU Decoder (`aludec.sv`):** Map MIPS `funct` codes and `aluop` signals to your 4-bit `alucontrol` lines.

---

## Phase 2: Architectural Selection (Control Logic)
**Goal:** Choose your control paradigm: Combinational, State-Machine, or Pipelined.

### A. Single-Cycle Mechanism (Combinational Control)
The simplest model where one instruction finishes every clock cycle.
1.  **Harvard Architecture**: Uses separate `imem.sv` and `dmem.sv` to allow fetching and data access in the same cycle.
2.  **Combinational Decoder**: The `maindec.sv` is purely combinational, generating all control signals based solely on the current opcode.
3.  **Long Critical Path**: Note that the clock speed is limited by the slowest instruction (usually `lw`).

### B. Multi-Cycle Mechanism (Finite State Machine)
The Multi-Cycle processor shares a single ALU and Memory to save hardware area.
1.  **Unified Memory (`mem.sv`)**: Instead of separate I-Mem and D-Mem, create a single memory port. Use the `IorD` signal to multiplex between `PC` and `ALUOut`.
2.  **The FSM (`fsm.sv`)**: Implement a state machine that cycles through Fetch, Decode, Execute, and Writeback.
    *   **State 0 (Fetch)**: Enable `IRWrite` to capture the instruction from memory.
    *   **State 1 (Decode)**: Pre-calculate branch targets.
    *   **State 2-11 (Execution)**: Route data through the ALU based on the opcode.
3.  **Datapath Registers**: Add non-architectural registers (`IR`, `MDR`, `A`, `B`, `ALUOut`) to hold data between clock cycles.

### C. Pipelined Mechanism (Hazard & Concurrency)
The Pipelined processor overlaps instructions to maximize throughput.
1.  **Pipeline Registers**: Insert registers between IF, ID, EX, MEM, and WB stages to store the state of different instructions.
2.  **Hazard Unit (`hazard.sv`)**: 
    *   **Forwarding**: Route data from the MEM and WB stages back to the EX stage to resolve RAW hazards without stalling.
    *   **Stalling**: If a `lw` instruction is followed by a dependent instruction, assert `stallF` and `stallD` while asserting `flushE` to insert a bubble.
3.  **Flush Logic**: If an interrupt (`intr`) occurs, assert `flushD` and `flushE` to scrub instructions currently in the pipeline.

---

## Phase 3: The System Bus (Memory, Input & Output)
**Goal:** Connect your CPU to the outside world.

1.  **Memory Subsystem:**
    *   `imem.sv` / `dmem.sv` (Harvard) or `mem.sv` (Von Neumann).
2.  **The Computer Wrapper (`computer.sv`):** Connect the CPU to memory.
3.  **I/O Mapping:**
    *   **Input:** The `intr` pin is your primary asynchronous input. When HIGH, it triggers the hardware exception vector.
    *   **Output:** Monitor memory writes to specific addresses to verify program success. Implement a universal halt condition that triggers `$finish` when the CPU writes to address `252` (`0xFC`).

---

## Phase 4: Memory Hierarchy (Caches)
**Goal:** Optimize performance by minimizing the "Memory Wall" penalty.

Real-world memory is slow. To simulate this, your `dmem.sv` should include a multi-cycle latency (e.g., 10 cycles).

1.  **Cache Controller**: Implement a module that sits between the CPU and Main Memory. 
    *   **Direct-Mapped**: Simplest to implement using a single tag and valid bit.
    *   **Fully-Associative**: Highest hit rate but most complex hardware logic.
2.  **Stall Logic**: When a cache miss occurs, the controller must assert a `mem_stall` signal to freeze the entire CPU pipeline until the memory data is ready.
3.  **Benchmarking**: Compare your performance with and without the cache.
    *   `make run CACHE_EN=0` (Baseline)
    *   `make run CACHE_EN=1` (Optimized)

---

## Phase 5: Software Ecosystem & Testing
**Goal:** Translate code and verify the hardware.

1.  **Assembler (`tools/assembler.py`):** Translate `.asm` MIPS files into `.exe` hex files.
2.  **Simulation & Verification:**
    *   Use the `Makefile` in your architecture's folder.
    *   Run simulation: `make all ASM=test_prog`.
    *   Check `tb_computer.vcd` for timing verification.
