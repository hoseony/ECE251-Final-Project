// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// OPCODE and FUNCTION FIELD(for R-Type) is declared here.
// =======================================================
`ifndef OPCODE
`define OPCODE

// ── OPCODES ──
// top 4 bits of every instruction [15:12]
`define OP_RTYPE  4'b0000  // R-type: use funct field [3:0] to determine operation
`define OP_ADDI   4'b0001  // R[rd] = R[rd] + signext(imm8)
`define OP_LW     4'b0010  // R[rd] = MEM[R9 + signext(imm8)]
`define OP_SW     4'b0011  // MEM[R9 + signext(imm8)] = R[rd]
`define OP_BEQ    4'b0100  // if R0 == R[rd], PC = PC+2 + signext(imm8)<<1
`define OP_BNE    4'b0101  // if R0 != R[rd], PC = PC+2 + signext(imm8)<<1
`define OP_J      4'b0110  // PC = {PC+2[15:13], imm12, 1'b0}
`define OP_JAL    4'b0111  // R15 = PC+2, PC = {PC+2[15:13], imm12, 1'b0}
`define OP_LI     4'b1000  // R[rd] = signext(imm8)
`define OP_ANDI   4'b1001  // R[rd] = R[rd] & signext(imm8)
`define OP_ORI    4'b1010  // R[rd] = R[rd] | signext(imm8)
`define OP_XORI   4'b1011  // R[rd] = R[rd] ^ signext(imm8)
`define OP_SLTI   4'b1100  // R[rd] = (R[rd] < signext(imm8)) ? 1 : 0
`define OP_LUI    4'b1101  // R[rd] = {imm8, 8'b0} (load upper immediate)
`define OP_JR     4'b1110  // PC = R[rd] 
`define OP_NOP    4'b1111  // no operation

// ── FUNCTION FIELDS for R-TYPE ──
// last 4 bits of R-type instruction [3:0]
// made it to match aluCTRL values so funct can be passed directly to ALU
`define R_AND     4'b0000  // R0 = R[rs] & R[rt]
`define R_OR      4'b0001  // R0 = R[rs] | R[rt]
`define R_ADD     4'b0010  // R0 = R[rs] + R[rt]
`define R_NOR     4'b0011  // R0 = ~(R[rs] | R[rt])
`define R_MFLO    4'b0100  // R0 = HiLo[15:0]  (lower half of multiply result)
`define R_MFHI    4'b0101  // R0 = HiLo[31:16] (upper half of multiply result)
`define R_SUB     4'b0110  // R0 = R[rs] - R[rt]
`define R_SLT     4'b0111  // R0 = (R[rs] < R[rt]) ? 1 : 0
`define R_XOR     4'b1000  // R0 = R[rs] ^ R[rt]
`define R_SLL     4'b1001  // R0 = R[rs] << R[rt][3:0]
`define R_SRL     4'b1010  // R0 = R[rs] >> R[rt][3:0]
`define R_MUL     4'b1011  // HiLo  = R[rs] * R[rt] (use MFLO/MFHI to read result)
`define R_PASSB   4'b1100  // R0 = R[rt]  (pass B through ALU)
`define R_PASSA   4'b1101  // R0 = R[rs]  (pass A through ALU)
`define R_NOT     4'b1110  // R0 = ~R[rs]
`define R_NEG     4'b1111  // R0 = -R[rs] (two's complement)

`endif
