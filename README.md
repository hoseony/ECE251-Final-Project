# ECE251B - 16-bit Pipelined CPU
**Course:** ECE251B — Computer Architecture, Prof. Rob Marano  
**Authors:** Hoseon Yu & Evan Dong

## Overview
This project implemented a 16-bit pipelined CPU in SystemVerilog, inspired by MIPS architecture and Intel 8080. It follows MIPS style instructions and pipelining structure (IF->ID->EX->ME->WB), and HI/LO for multiplication, with Intel 8080 style accumulator, and flag register.

## Architecture Summary
 
```
IF → ID → EX → MEM → WB
```
 
| Stage | Module | Description |
|-------|--------|-------------|
| IF | `datapath.sv` | Fetch instruction from `imem`, compute PC+2 |
| ID | `datapath.sv`, `controller.sv` | Decode instruction, read register file, resolve branches |
| EX | `alu.sv`, `datapath.sv` | ALU operation, forwarding multiplexers |
| MEM | `dmem.sv`, `cache_directMapped.sv` | Load/store with simulated latency and cache |
| WB | `datapath.sv`, `registerFile.sv` | Write result back to register file |
  
## ISA Reference
All instructions are **16 bits wide**. The top 4 bits `[15:12]` are the opcode.

### Instruction Formats
 
```
R-type:  [ 4 op | 4 rs | 4 rt | 4 funct ]
I-type:  [ 4 op | 4 rd | 8 imm          ]
J-type:  [ 4 op | 12 imm                ]
```
 
### Opcodes
 
| Opcode | Instruction | Operation |
|--------|----------|-----------|
| `0000` | R-type   | Determined by `funct[3:0]` |
| `0001` | `ADDI`   | `R[rd] = R[rd] + signext(imm8)` |
| `0010` | `LW`     | `R[rd] = MEM[R9 + signext(imm8)]` |
| `0011` | `SW`     | `MEM[R9 + signext(imm8)] = R[rd]` |
| `0100` | `BEQ`    | `if R0 == R[rd]: PC = PC+2 + signext(imm8)<<1` |
| `0101` | `BNE`    | `if R0 != R[rd]: PC = PC+2 + signext(imm8)<<1` |
| `0110` | `J`      | `PC = {PC+2[15:13], imm12, 1'b0}` |
| `0111` | `JAL`    | `R15 = PC+2; PC = {PC+2[15:13], imm12, 1'b0}` |
| `1000` | `LI`     | `R[rd] = signext(imm8)` |
| `1001` | `ANDI`   | `R[rd] = R[rd] & signext(imm8)` |
| `1010` | `ORI`    | `R[rd] = R[rd] \| signext(imm8)` |
| `1011` | `XORI`   | `R[rd] = R[rd] ^ signext(imm8)` |
| `1100` | `SLTI`   | `R[rd] = (R[rd] < signext(imm8)) ? 1 : 0` |
| `1101` | `LUI`    | `R[rd] = {imm8, 8'b0}` |
| `1110` | `JR`     | `PC = R[rd]` |
| `1111` | `NOP`    | No operation |
 
### R-Type Function Fields
 
| `funct` | Instruction | Operation |
|---------|----------|-----------|
| `0000` | `AND`   | `R0 = R[rs] & R[rt]` |
| `0001` | `OR`    | `R0 = R[rs] \| R[rt]` |
| `0010` | `ADD`   | `R0 = R[rs] + R[rt]` |
| `0011` | `NOR`   | `R0 = ~(R[rs] \| R[rt])` |
| `0100` | `MFLO`  | `R0 = HiLo[15:0]` |
| `0101` | `MFHI`  | `R0 = HiLo[31:16]` |
| `0110` | `SUB`   | `R0 = R[rs] - R[rt]` |
| `0111` | `SLT`   | `R0 = (R[rs] < R[rt]) ? 1 : 0` |
| `1000` | `XOR`   | `R0 = R[rs] ^ R[rt]` |
| `1001` | `SLL`   | `R0 = R[rs] << R[rt][3:0]` |
| `1010` | `SRL`   | `R0 = R[rs] >> R[rt][3:0]` |
| `1011` | `MUL`   | `HiLo = R[rs] * R[rt]` (signed) |
| `1100` | `PASSB` | `R0 = R[rt]` |
| `1101` | `PASSA` | `R0 = R[rs]` |
| `1110` | `NOT`   | `R0 = ~R[rs]` |
| `1111` | `NEG`   | `R0 = -R[rs]` (two's complement) |
 
### Special Registers
 
| Register | |
|----------|------|
| `R0`  | Accumulator — destination for all R-type results |
| `R9`  | Base pointer — used as base address for `LW`/`SW` |
| `R12` | Flags register — written by ALU flag-writing instructions |
| `R15` | Return address — written by `JAL` |
 
### Flags Register (R12)
 
| Bit | Flag |
|-----|------|
| 0 | Zero |
| 1 | Negative |
| 2 | Carry |
| 3 | Overflow |


## Simulation

### Prerequisites
- [Icarus Verilog](https://github.com/steveicarus/iverilog)

### Bulid and Run

#### Compiling Program
In `programs` directory
```bash
make asm=test.asm
```
or 
```bash
python3 ../tools/assembler.py test.asm program
```

#### Compiling Computer and Simulating
In `pipelined-computer` directory
```bash
make
```
or 
```bash
iverilog -g2012 -o sim tb_computer.sv
./sim
```

#### GTKwave
in `pipelined-computer` directory, after compilation
```bash
gtkwave ./tb_computer.vcd
```

## Timing Diagram
![TimingDiagramR-I](/assets-readme/timing-diagram-R-I.png)

The following image shows timing diagram of the following instructions.
```asm
li r1, 5
li r2, 3
add r1, r2
halt:
j halt
```

which translates into
```asm
8105
8203
0212
6003
```
