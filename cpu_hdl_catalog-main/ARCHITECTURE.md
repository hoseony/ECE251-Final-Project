# MIPS CPU Architecture Documentation

This project catalogs three fundamental ways to implement the MIPS32 RISC instruction set.

## 1. Unified Solution Architecture

All three implementations share the same external memory and I/O interface.

```mermaid
graph TD
    subgraph System Bus
        CLK[Clock Generator]
        IO[Halt Output addr 252]
    end

    subgraph Memory
        MEM[(Unified Instruction/Data)]
    end

    subgraph CPU[MIPS CPU Implementation]
        SINGLE[Single-Cycle]
        MULTI[Multi-Cycle]
        PIPE[Pipelined]
    end

    CLK --> CPU
    CPU <--> MEM
    CPU --> IO
```

---

## 2. Multi-Cycle State Machine (FSM)

The multi-cycle implementation shares a single ALU and memory, transitioning through states to complete an instruction.

```mermaid
stateDiagram-v2
    [*] --> Fetch
    Fetch --> Decode
    Decode --> MemAdr: lw/sw
    Decode --> ExecuteR: R-type
    Decode --> Branch: beq
    Decode --> ADDIExec: addi
    Decode --> Jump: j

    MemAdr --> MemRead: lw
    MemAdr --> MemWrite: sw
    MemRead --> MemWriteback
    MemWriteback --> Fetch
    MemWrite --> Fetch

    ExecuteR --> ALUWriteback
    ALUWriteback --> Fetch

    Branch --> Fetch
    ADDIExec --> ADDIWriteback
    ADDIWriteback --> Fetch
    Jump --> Fetch
```

### FSM State Mechanisms
To reuse hardware (ALU and Memory), the FSM generates control signals that change the function of components each cycle:

1.  **Fetch**: Reads the instruction from memory (`IR = Mem[PC]`) and increments the PC (`PC = PC + 4`). 
    *   *Signals*: `IorD=0`, `MemRead=1`, `IRWrite=1`, `ALUSrcA=0`, `ALUSrcB=01`, `ALUOp=00`, `PCWrite=1`.
2.  **Decode**: Computes the branch target address in advance (`ALUOut = PC + (sign-ext(imm) << 2)`) and reads registers into `A` and `B`.
    *   *Signals*: `ALUSrcA=0`, `ALUSrcB=11`, `ALUOp=00`.
3.  **ExecuteR**: Performs the R-type operation using operands from registers `A` and `B`.
    *   *Signals*: `ALUSrcA=1`, `ALUSrcB=00`, `ALUOp=10`.
4.  **MemAdr**: Computes the effective memory address for `lw` or `sw`.
    *   *Signals*: `ALUSrcA=1`, `ALUSrcB=10`, `ALUOp=00`.
5.  **MemRead / MemWrite**: Accesses unified memory using the computed address in `ALUOut`.
    *   *Signals (Read)*: `IorD=1`, `MemRead=1`.
    *   *Signals (Write)*: `IorD=1`, `MemWrite=1`.
6.  **Writeback**: Commits the ALU result or memory data back to the register file.
    *   *Signals (ALU)*: `RegDst=1`, `RegWrite=1`, `MemToReg=0`.
    *   *Signals (Mem)*: `RegDst=0`, `RegWrite=1`, `MemToReg=1`.

---

## 3. Pipelined Architecture (5 Stages)

The pipelined implementation overlaps instruction execution using registers between stages.

```mermaid
graph LR
    subgraph IF [Fetch]
        PC[Program Counter]
    end

    subgraph ID [Decode]
        RF[Register File]
        HU[Hazard Unit]
    end

    subgraph EX [Execute]
        ALU[ALU]
    end

    subgraph MEM [Memory]
        DM[Data Memory]
    end

    subgraph WB [Writeback]
        REG[Reg Write]
    end

    PC -->|instr| RF
    RF -->|operands| ALU
    ALU -->|result| DM
    DM -->|data| REG
    REG -.->|forward/write| RF
    HU -.->|stall/flush| PC
    HU -.->|forward| ALU
```

---

## 4. Pipelined Cache Architecture (Memory Hierarchy)

The Pipelined Cached implementation introduces a Cache Controller between the CPU and Main Memory to mitigate the performance penalty of slow DRAM.

```mermaid
graph TD
    subgraph CPU [MIPS Pipelined CPU]
        DP[Datapath]
    end

    subgraph Memory Hierarchy
        L1[L1 Cache Controller]
        DRAM[(Main Memory / dmem)]
    end

    DP <-->|addr, rd, wr, data| L1
    L1 <-->|miss: fetch block| DRAM
    L1 -->|mem_stall| DP
```

### Cache Controller Mechanisms
1.  **Direct-Mapped**: Simplest mapping where each memory address maps to exactly one cache line. Uses a Tag and Valid bit.
2.  **Set-Associative**: Balance between complexity and hit rate. Multiple "ways" per set.
3.  **Fully-Associative**: Any memory block can go into any cache line. Uses CAM (Content Addressable Memory) logic for parallel tag matching.
4.  **Ready/Stall Handshake**: The CPU asserts `memread/memwrite`. If a miss occurs, the Cache asserts `mem_stall` and interacts with `dmem` until `dmem_ready` is signaled.

---

## 5. Hardware Standard: 4-bit ALU Control

All architectures use this unified 4-bit control mapping:

| ALUControl | Operation | MIPS Funct/Op |
| :--- | :--- | :--- |
| `0000` | AND | `0x24` |
| `0001` | OR | `0x25` |
| `0010` | ADD | `0x20` / `0x08` (addi) |
| `0011` | NOR | `0x27` |
| `0100` | MFLO | `0x12` |
| `0101` | MFHI | `0x10` |
| `0110` | SUB | `0x22` |
| `0111` | SLT | `0x2a` |
| `1000` | MULT | `0x18` |
| `1001` | DIV | `0x1a` |

---

## 5. Unimplemented Designs (Future Work)

- **Precise Exception Handling**: The pipelined model needs to capture the correct PC in the `EPC` register during a flush to allow for instruction re-execution.
- **Dynamic Branch Prediction**: Replace the current stall-based or static prediction with a Branch Target Buffer (BTB).
- **L1 Cache**: Separate Instruction and Data caches to resolve memory contention in the pipelined model.
- **Floating Point Unit (FPU)**: Integration of MIPS Coprocessor 1.
