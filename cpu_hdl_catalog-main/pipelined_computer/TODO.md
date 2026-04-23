# Architecture & Bug Fix TODOs (Pipelined CPU with Exceptions)

This document outlines critical structural bugs and architectural flaws identified during the SystemVerilog code review of the 5-stage MIPS32 pipelined processor. 

Please assign these tasks to the engineering team for immediate remediation before synthesizing for FPGA deployment or advancing the curriculum.

---

## 1. EPC Logic Error (Instruction Re-execution Bug)
**Severity:** Critical
**File:** `datapath.sv`

### Description
The asynchronous interrupt logic currently captures the wrong Program Counter for the Exception Program Counter (`EPC`), leading to the double-execution of instructions upon returning from an interrupt.
* When an interrupt fires (`Exception_Flag = 1`), the hazard unit sets `flushE = 1` and `flushD = 1`.
* `flushE` clears the **ID/EX** register, squashing the instruction that was in Decode. 
* However, the **EX/MEM** register has no synchronous clear. The instruction currently in Execute *survives* and proceeds to Memory and Writeback.
* The bug is in `datapath.sv`: `EPC <= pcplus4E - 32'd4;`. This captures the PC of the instruction in Execute (which successfully completed).
* If the OS handler returns, it will re-execute the instruction that was in EX, while the instruction that was flushed in ID is lost forever.

### Recommended Solution
Change the `EPC` latch logic to capture the PC of the flushed Decode stage instruction:
```systemverilog
// In datapath.sv
always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        EPC <= 32'b0;
    end else if (Exception_Flag) begin
        // Capture the PC of the instruction in Decode that is being flushed
        EPC <= pcplus4D - 32'd4; 
    end
end
```

---

## 2. ALU Control Collision (MFHI & Division Overlap)
**Severity:** High
**Files:** `alu.sv`, `aludec.sv`

### Description
The `alucontrol` signal is only 3 bits wide, which allows for 8 unique operations. The current mapping double-allocates `3'b101`:
* `aludec.sv` maps `mfhi` to `alucontrol = 3'b101`.
* In `alu.sv`, the combinational block correctly outputs `HiLo[63:32]` when `alucontrol == 3'b101`.
* However, in the sequential `always @(negedge clk)` block in `alu.sv`, `3'b101` is *also* used to execute a Division operation (`a / b`).
* **Impact:** Every time `mfhi` is called to read the HI register, the ALU simultaneously executes a division, permanently corrupting the `HiLo` register with garbage values before it can be used again.

### Recommended Solution
Increase the width of the `alucontrol` signal from 3 bits to 4 bits across the pipeline to expand the instruction space.
1. Update `aludec.sv`, `controller.sv`, `datapath.sv`, and `alu.sv` to use `logic [3:0] alucontrol`.
2. Reassign `DIV` to a new control code (e.g., `4'b1000`).
3. Retain `MFHI` as `4'b0101` but remove it from the `negedge clk` division block.

---

## 3. ALU Control Collision (MULT & NOR Overlap)
**Severity:** High
**Files:** `alu.sv`, `aludec.sv`

### Description
Similar to Issue 2, `alucontrol = 3'b011` is overloaded.
* `aludec.sv` maps `mult` to `3'b011`.
* The `negedge clk` block in `alu.sv` correctly calculates the 64-bit product into `HiLo`.
* However, the combinational block in `alu.sv` uses `3'b011` to compute `NOR` (`~(a | b)`).
* **Impact:** When a `mult` instruction is passing through the EX stage, the ALU outputs a `NOR` result. Because `maindec.sv` asserts `regwrite = 1` for all R-Type operations, the datapath will write this erroneous `NOR` result into the `rd` register.

### Recommended Solution
Expanding `alucontrol` to 4 bits (as requested in Issue 2) resolves this.
1. Assign `MULT` to a unique control code (e.g., `4'b1001`).
2. Update `aludec.sv` to issue `4'b1001` for the `mult` funct.
3. Remove the overlap so `NOR` remains purely combinational and `MULT` remains purely sequential (setting combinational `result` to 0 or ignoring it).

---

## 4. [RESOLVED] Exception Vector Memory Aliasing
**Severity:** Medium
**Files:** `imem.sv`, `dmem.sv`, `computer.sv`, `test_exceptions.asm`, `prog4_interrupts.asm`

### Description
*Resolved: Memory depths were increased to `r=8` and handler targets updated to `0x180` to prevent bounds aliasing.*

---

## 5. Testbench Port Instantiation Mismatch
**Severity:** Low / Build Failure
**File:** `tb_computer.sv`

### Description
The generic `tb_computer.sv` wrapper initiates the `computer` module but omits the newly added `intr` port. This will cause compilation failures in strict Verilog simulators like Icarus Verilog.
```systemverilog
// Current broken instantiation
computer dut(clk, reset, writedata, dataadr, memwrite);
```

### Recommended Solution
Inject a dedicated `intr` logic signal initialized to 0.
```systemverilog
logic intr = 0;
computer dut(clk, reset, intr, writedata, dataadr, memwrite);
```