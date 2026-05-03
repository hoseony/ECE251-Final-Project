// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// ADDER
// =======================================================
`ifndef ADDER
`define ADDER

`timescale 1ns/100ps

module adder(
    input  logic [15:0] A,
    input  logic [15:0] B,
    output logic [15:0] Y
);

    assign Y = A + B;
endmodule

`endif
// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// ALU module
// =======================================================

// * apparently it throws an error when I do any bitselections in always_comb, so it ended up becoming bit massy

`ifndef ALU
`define ALU

`timescale 1ns/100ps

module alu(
    input  logic         clk,
    input  logic [15:0]  a, b,
    input  logic [3:0]   aluCTRL,
    output logic [15:0]  result,
    output logic         zero,
    output logic         negative,
    output logic         carry,
    output logic         overflow
);
    
    // ============ DLD addition trick ===========
    logic [15:0] condinvb;      // b or ~b depending on add/sub 
    logic [15:0] sumSlt;
    logic [16:0] fullSum;

    assign condinvb = aluCTRL[2] ? ~b : b;
    assign fullSum = {1'b0, a} + {1'b0, condinvb} + {16'b0, aluCTRL[2]};
    assign sumSlt = fullSum[15:0];
    
    // ============ FLAGS ============
    assign zero = (result == 16'b0); // zero flag
    assign negative = result[15];    // negative flag
    assign carry = (aluCTRL == 4'b0010 || aluCTRL == 4'b0110) ? fullSum[16] : 1'b0;      // carry flag

    logic aSign, bSign, sumSign, bSg;
    assign aSign = a[15];
    assign bSign = condinvb[15];
    assign sumSign = sumSlt[15];
    assign bSg = b[15];


    always_comb begin
        if (aluCTRL == 4'b0010 || aluCTRL == 4'b0110) begin
           // if both input same sign but result sign diff
           if (aSign == bSign && sumSign != aSign)
                overflow = 1'b1;
           else 
                overflow = 1'b0;
        end else begin
            overflow = 1'b0;
        end
    end

    // ============ ALU operation ============

    // For multiplication:
    logic [31:0] HiLo;              // 16 bits x 16 bits = max 32 bits
    logic [15:0] HiLo_lo;           // lower 16 bits
    logic [15:0] HiLo_hi;           // upper 16 bits

    assign HiLo_lo = HiLo[15:0];    
    assign HiLo_hi = HiLo[31:16];

    // for SLL and SRL
    logic [3:0] bShiftAmt;
    assign bShiftAmt = b[3:0];

    always_comb begin
        case (aluCTRL)
            4'b0000: result = a & b;        // AND
            4'b0001: result = a | b;        // OR
            4'b0010: result = sumSlt;       // ADD
            4'b0011: result = ~(a | b);     // NOR
            4'b0100: result = HiLo_lo;      // MFLO
            4'b0101: result = HiLo_hi;      // MFHI
            4'b0110: result = sumSlt;       // SUB
            4'b0111: begin                  // SLT
                  if (aSign != bSg)
                      if (aSign > bSg)
                          result = 16'b1;
                      else 
                          result = 16'b0;
                  else
                      if (a < b)
                           result = 16'b1;
                      else 
                          result = 16'b0;
            end
            4'b1000: result = a ^ b;           // XOR
            4'b1001: result = a << bShiftAmt;  // SLL
            4'b1010: result = a >> bShiftAmt;  // SRL
            4'b1100: result = b;

            default: result = 16'b0;
        endcase
    end

    // ============ signed multiplication ============
    logic signed [15:0] aSigned;
    logic signed [15:0] bSigned;
    logic signed [31:0] HiLoSigned;

    assign HiLoSigned = aSigned * bSigned;

    assign aSigned = a;
    assign bSigned = b;

    always_ff @(negedge clk) begin
        case (aluCTRL)
            4'b1011: HiLo <= HiLoSigned;         // MUL
            default: HiLo <= HiLo;
        endcase
    end
endmodule

`endif
// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// ALU decoder
// =======================================================

`ifndef ALUDEC
`define ALUDEC

`timescale 1ns/100ps

import opcode_pkg::*;

module aluDecoder(
    input logic [1:0] aluOP, // 00: add | 01: subtract | 10: function field
    input logic [3:0] funct,

    output logic [3:0] aluCTRL
);

    always_comb begin
        case (aluOP)
            2'b00: aluCTRL = R_ADD; // 00: add
            2'b01: aluCTRL = R_SUB; // 01: subtract
            2'b10: aluCTRL = funct; // 10: function field
            2'b11: aluCTRL = R_PASSB;
            
            default: aluCTRL = R_ADD;
        endcase
    end
endmodule

`endif
// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// COMPUTER
// =======================================================

`ifndef COMPUTER
`define COMPUTER

`timescale 1ns/100ps

`include "cpu.sv"
`include "mem.sv"

module computer(
    input  logic        clk, reset,

    output logic [15:0] writeData,
    output logic [15:0] dataAddress,
    output logic        memWrite
);

    logic [15:0] pc;
    logic [15:0] aluOut;
    logic [15:0] readData;
    logic [15:0] memAddress;

    cpu cpuUnit(
        .clk(clk),
        .reset(reset),
        .readData(readData),
        .memWrite(memWrite),
        .pc(pc),
        .aluOut(aluOut),
        .writeData(writeData),
        .memAddress(memAddress)
    );

    assign dataAddress = memAddress;

    mem memory(
        .clk(clk),
        .memWrite(memWrite),
        .address(memAddress[6:1]),
        .writeData(writeData),
        .readData(readData)
    );

endmodule

`endif
// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// Controller (mainDecoder + aluDecoder)
// =======================================================

`ifndef CTRL
`define CTRL

`timescale 1ns/100ps

`include "fsm.sv"
`include "aluDecoder.sv"

module controller(
    input  logic       clk, reset,
    input  logic [3:0] opcode,
    input  logic [3:0] funct,
    input  logic       zero,

    output logic       irWrite,
    output logic       mdrWrite,
    output logic       iord,
    output logic       memWrite,
    output logic       regWrite,
    output logic       memToReg,
    output logic       aluSrcA,
    output logic [1:0] regDst,
    output logic [1:0] aluSrcB,
    output logic [1:0] pcSrc,

    output logic       flagWrite,
    output logic       jumpLink,
    output logic       memBase,
    output logic       branchSrc,
    output logic       pcEn,
    output logic       readRd,

    output logic [3:0] aluCTRL
);

    logic [1:0] aluOP;
    logic pcWrite, pcWriteCond;
    logic branchEq, branchNe;

    fsm fs(
        .clk(clk), .reset(reset), .opcode(opcode),
        .irWrite(irWrite), .mdrWrite(mdrWrite), 
        .pcWrite(pcWrite), .pcWriteCond(pcWriteCond),
        .iord(iord), .memWrite(memWrite), .regWrite(regWrite),
        .memToReg(memToReg), .aluSrcA(aluSrcA), .aluSrcB(aluSrcB),
        .pcSrc(pcSrc), .aluOP(aluOP), .regDst(regDst),
        .flagWrite(flagWrite), .jumpLink(jumpLink),
        .branchEq(branchEq), .branchNe(branchNe),
        .memBase(memBase), .branchSrc(branchSrc),
        .readRd(readRd)
    ); 


    aluDecoder ad(
        .aluOP(aluOP),
        .funct(funct),
        .aluCTRL(aluCTRL)
    );

    assign pcEn = pcWrite | (pcWriteCond & ((branchEq & zero) | (branchNe & ~zero)));
endmodule

`endif
// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// CPU
// =======================================================

`ifndef CPU
`define CPU

`timescale 1ns/100ps

`include "controller.sv"
`include "datapath.sv"

module cpu(
    input  logic        clk, reset,

    input  logic [15:0] readData,

    output  logic        memWrite,
    output  logic [15:0] pc,
    output  logic [15:0] aluOut,
    output  logic [15:0] writeData,
    output  logic [15:0] memAddress
);
    // send help...
    logic        irWrite;
    logic        mdrWrite;
    logic        iord;
    logic        regWrite;
    logic        memToReg;
    logic        aluSrcA;
    logic [1:0]  aluSrcB;
    logic [1:0]  regDst;
    logic [1:0]  pcSrc;
    logic        pcEn;

    logic        flagWrite;
    logic        jumpLink;
    logic        memBase;
    logic        branchSrc;
    logic        readRd;

    logic [3:0]  aluCTRL;
    logic        zero;
    logic [15:0] instrOut; 

    controller ctrl(
        .clk(clk),
        .reset(reset),
        .opcode(instrOut[15:12]),
        .funct(instrOut[3:0]),
        .zero(zero),
        .irWrite(irWrite),
        .mdrWrite(mdrWrite),
        .iord(iord),
        .memWrite(memWrite),
        .regWrite(regWrite),
        .memToReg(memToReg),
        .aluSrcA(aluSrcA),
        .regDst(regDst),
        .aluSrcB(aluSrcB),
        .pcSrc(pcSrc),
        .flagWrite(flagWrite),
        .jumpLink(jumpLink),
        .memBase(memBase),
        .branchSrc(branchSrc),
        .pcEn(pcEn),
        .aluCTRL(aluCTRL),
        .readRd(readRd)
    );

    datapath dp(
        .clk(clk),
        .reset(reset),
        .pcEn(pcEn),
        .irWrite(irWrite),
        .mdrWrite(mdrWrite),
        .iord(iord),
        .regWrite(regWrite),
        .memToReg(memToReg),
        .jumpLink(jumpLink),
        .memBase(memBase),
        .branchSrc(branchSrc),
        .aluSrcA(aluSrcA),
        .aluSrcB(aluSrcB),
        .regDst(regDst),
        .pcSrc(pcSrc),
        .aluCTRL(aluCTRL),
        .flagWrite(flagWrite),
        .readData(readData),
        .zero(zero),
        .pc(pc),
        .aluOut(aluOut),
        .writeData(writeData),
        .memAddress(memAddress),
        .instrOut(instrOut),
        .readRd(readRd)
    );

endmodule

`endif
// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// D Flip Flop
// =======================================================

`ifndef DFF
`define DFF

`timescale 1ns/100ps

module dff(
    input  logic        clk, r,
    input  logic [15:0] D,
    output logic [15:0] Q
);

    always_ff @(posedge clk) begin
        if (r) // if reset high, 0
            Q <= 16'b0; 
        else 
            Q <= D;
    end
endmodule

`endif
// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// Data Path
// =======================================================

`ifndef DATAPATH
`define DATAPATH

`timescale 1ns/100ps

`include "adder.sv"
`include "alu.sv"
`include "dFF.sv"
`include "mux2.sv"
`include "mux4.sv"
`include "signExtend.sv"
`include "registerFile.sv"
`include "sl1.sv"

module datapath(
    input  logic           clk, reset,

    input  logic           pcEn,
    input  logic           irWrite,
    input  logic           mdrWrite,
    input  logic           iord,
    input  logic           regWrite,
    input  logic           memToReg, 
    input  logic           jumpLink,
    input  logic           memBase,
    input  logic           branchSrc,
    input  logic           aluSrcA,
    input  logic [1:0]     aluSrcB,
    input  logic [1:0]     regDst,
    input  logic [1:0]     pcSrc,
    input  logic [3:0]     aluCTRL,
    input  logic           flagWrite,
    input  logic           readRd,

    input  logic [15:0]    readData,

    output logic           zero,
    output logic [15:0]    pc,
    output logic [15:0]    aluOut,
    output logic [15:0]    writeData,
    output logic [15:0]    memAddress,
    output logic [15:0]    instrOut
);
    // ====================== Internal Signals ========================
    logic [15:0] pcNext;
    logic [15:0] signImm, signImmSh;

    logic [3:0]  readReg1, readReg2;
    logic [3:0]  writeReg;

    logic [15:0] readData1, readData2;
    logic [15:0] srcA, srcB;            // ALU input

    logic [15:0] aluOrMem;
    logic [15:0] result;

    logic negative, carry, overflow;

    // ======================Registers (in between states) ========================

    // IR
    logic [15:0] instrReg;
    always_ff @(posedge clk) begin
        if (reset)
            instrReg <= 16'b0;
        else if (irWrite) 
            instrReg <= readData;
    end

    assign instrOut = instrReg;

    // A and B reg
    logic [15:0] aReg, bReg;
    always_ff @(posedge clk) begin
        if (reset) begin
            aReg <= 16'b0;
            bReg <= 16'b0;
        end else begin
            aReg <= readData1;
            bReg <= readData2;
        end
    end

    // aluOut
    logic [15:0] aluRegOut;
    always_ff @(posedge clk) begin
        if (reset)
            aluRegOut <= 16'b0;
        else
            aluRegOut <= aluOut;
    end

    // memory Data
    logic [15:0] memDataReg;
    always_ff @(posedge clk) begin
        if (reset)
            memDataReg <= 16'b0;
        else if (mdrWrite) 
            memDataReg <= readData;
    end

    // ======================PC Logic ========================
    always_ff @(posedge clk) begin
        if (reset) pc <= 16'b0;
        else if (pcEn) pc <= pcNext;
    end

    logic [15:0] pcJump;
    assign pcJump = {pc[15:13], instrReg[11:0], 1'b0};

    always_comb begin
        case (pcSrc)
            2'b00:   pcNext = aluOut;
            2'b01:   pcNext = aluRegOut;
            2'b10:   pcNext = pcJump;
            default: pcNext = aluOut;
        endcase
    end

    mux2 #(16) addrMux(pc, aluRegOut, iord, memAddress);

    signExtend se(.A(instrReg[7:0]), .Y(signImm));
    sl1        immsh(.A(signImm), .Y(signImmSh));

    // ======================Register File ========================

    // ALU inputA |            rs(R-Type), R9: memory pointer, R0: accumulator
    always_comb begin
        if (memBase)
            readReg1 = 4'd9;
        else if (branchSrc)
            readReg1 = 4'd0;
        else if (readRd)
            readReg1 = instrReg[11:8];   // ADDI reads rd as source
        else
            readReg1 = instrReg[7:4];    // R-type rs
    end    

    // ALU inputB | R-Type rt, I-Type rd
    assign readReg2 = instrReg[11:8];

    // Destination 
    // Remember from mainDecoder:
    // regDst [1:0], 00: Accumulator | 01: rd field (I-type) | 10: R15 $ra
    mux4      #(4)  wrMux(4'd0, instrReg[11:8], 4'd15, 4'd0, regDst, writeReg);

    // for now, always update flag
    logic [15:0] flagsData;
    assign flagsData = {12'b0, overflow, carry, negative, zero};

    registerFile    rf(clk, regWrite, readReg1, readReg2, writeReg, result, readData1, readData2, flagWrite, flagsData);

    // ======================ALU logic ========================
    mux2      #(16) srcAMux(pc, aReg, aluSrcA, srcA);
    mux4      #(16) srcBMux(bReg, 16'd2, signImm, signImmSh, aluSrcB, srcB);
    
    alu             aluUnit(clk, srcA, srcB, aluCTRL, aluOut, zero, negative, carry, overflow);

    // ======================WB ========================
    assign writeData = bReg;

    mux2      #(16) resultMux(aluRegOut, memDataReg, memToReg, aluOrMem);
    mux2      #(16) jalMux(aluOrMem, aluRegOut, jumpLink, result);

endmodule

`endif
// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// Finite State Machine
// =======================================================

`ifndef FSM
`define FSM

`timescale 1ns/100ps

import opcode_pkg::*;

module fsm (
    // ref: Appendix D-29 from textbook
    input  logic        clk, reset,
    input  logic [3:0]  opcode,      // yeah, opcode

    output logic        irWrite,     // IR (Instruction Register)
    output logic        mdrWrite,    // MDR (Memory Data Register)
    output logic        pcWriteCond, // Conditional PC
    output logic        iord,        // choose address 0: pc | 1: alu out register  
    output logic        memWrite,    // 1: write to a memory (sw)
    output logic        regWrite,    // 1: write to register
    output logic        memToReg,    // 1: data from memory | 0: data fromregister
    output logic        aluSrcA,     // 0: pc | 1: A register
    output logic        pcWrite,

    output logic [1:0]  regDst,      // 00: Accumulator | 01: rd field (I-type) | 10: R15 $ra
    output logic [1:0]  aluSrcB,     // 00: register B | 01: constant 2
                                     // 10: output of sign extend | 11: signImmSh (sign immediate shift < 1)
    output logic [1:0]  pcSrc,    // 00: output of ALU to pc | 01: aluOutReg | 10: jump
    output logic [1:0]  aluOP,       // 00: add | 01: sub | 10: funct

    output logic        flagWrite,   // 
    output logic        jumpLink,    // pc+2 
    output logic        branchEq,    //
    output logic        branchNe,    //
    output logic        memBase,     // R9 is readReg1
    output logic        branchSrc,   // R0 is readReg1
    output logic        readRd
);

    typedef enum logic [3:0] {
            FETCH     = 4'b0000, // pc memory -> IR, pc = pc + 2
            DECODE    = 4'b0001, // read regs, compute branch target
            MEMADR    = 4'b0010, // compute address for lw / sw
            MEMREAD   = 4'b0011, // read memory (lw)
            MEMWB     = 4'b0100, // mem -> reg (lw)
            MEMWRITE  = 4'b0101, // write to memory (sw)
            EXECUTER  = 4'b0110, // R-Type execution
            ALUWB     = 4'b0111, // R-Type write back
            BRANCH    = 4'b1000, // beq / bne
            ADDIEXEC  = 4'b1001, // addi execution
            ADDIWB    = 4'b1010, // addi write back
            JUMP      = 4'b1011, // j / jal
            JALWB     = 4'b1100, // jal (write back)
            LIEXEC    = 4'b1101,
            LIWB      = 4'b1110
    } state_t;

    state_t state, nextState;

    always_ff @(posedge clk or posedge reset)
        if (reset) state <= FETCH;
        else state <= nextState;

    // next state logic
    always_comb begin
        case (state)
            FETCH:      nextState = DECODE;
            DECODE:     case (opcode)
                            OP_RTYPE: nextState = EXECUTER;
                            OP_ADDI:  nextState = ADDIEXEC;
                            OP_LW:    nextState = MEMADR;
                            OP_SW:    nextState = MEMADR;
                            OP_BEQ:   nextState = BRANCH;
                            OP_BNE:   nextState = BRANCH;
                            OP_J:     nextState = JUMP;
                            OP_JAL:   nextState = JUMP;
                            OP_LI:    nextState = LIEXEC;
                            default:  nextState = FETCH;
                        endcase
            MEMADR:     begin 
                if (opcode == OP_LW)
                    nextState = MEMREAD;
                else 
                    nextState = MEMWRITE;
            end
            MEMREAD:    nextState = MEMWB;
            MEMWB:      nextState = FETCH;
            MEMWRITE:   nextState = FETCH;
            EXECUTER:   nextState = ALUWB;
            ALUWB:      nextState = FETCH;
            BRANCH:     nextState = FETCH;
            ADDIEXEC:   nextState = ADDIWB;
            ADDIWB:     nextState = FETCH;
            JUMP:       begin
                if (opcode == OP_JAL)
                    nextState = JALWB;
                else 
                    nextState = FETCH;
            end
            JALWB:      nextState = FETCH;
            LIEXEC: nextState = LIWB;
            LIWB:   nextState = FETCH;
            default:    nextState = FETCH;
        endcase
    end

    // output logic
    always_comb begin
        // default
        irWrite = 1'b0;
        mdrWrite = 1'b0;
        pcWrite = 1'b0;
        pcWriteCond = 1'b0;
        iord = 1'b0;
        memWrite = 1'b0;
        regWrite = 1'b0;
        memToReg = 1'b0;
        aluSrcA = 1'b0;
        flagWrite = 1'b0;
        jumpLink = 1'b0;
        branchEq = 1'b0;
        branchNe = 1'b0;
        memBase = 1'b0;
        branchSrc = 1'b0;
        regDst = 2'b00;
        aluSrcB = 2'b00;
        pcSrc = 2'b00;
        aluOP = 2'b00;
        readRd = 1'b0;

        case (state)
            // send help, this is too much to write comments 
            FETCH: begin
                irWrite = 1;
                pcWrite = 1;
                aluSrcA = 0;
                aluSrcB = 2'b01;
                aluOP   = 2'b00;
                pcSrc   = 2'b00;
            end

            DECODE: begin
                aluSrcA = 0;
                aluSrcB = 2'b11;
                memBase = (opcode == OP_LW  || opcode == OP_SW); 
                branchSrc = (opcode == OP_BEQ || opcode == OP_BNE);
                readRd = (opcode == OP_ADDI);
            end

            MEMADR: begin
                aluSrcA = 1;
                aluSrcB = 2'b10;
                aluOP   = 2'b00;
            end

            MEMREAD: begin
                iord = 1;
                mdrWrite = 1;
            end

            MEMWB: begin
                regWrite = 1;
                memToReg = 1;
                regDst = 2'b01;
            end

            MEMWRITE: begin
                memWrite = 1;
                iord = 1;
            end

            EXECUTER: begin
                aluSrcA = 1;
                aluSrcB = 2'b00;
                aluOP = 2'b10;
                flagWrite = 1;
            end

            ALUWB: begin
                regWrite = 1;
                regDst = 2'b00;
            end

            // Branch compare R0 and rd (idk if I like it)
            BRANCH: begin
                aluSrcA = 1;
                aluSrcB = 2'b00;
                aluOP = 2'b01;
                pcWriteCond = 1;
                pcSrc = 2'b01;
                branchEq = (opcode == OP_BEQ);
                branchNe = (opcode == OP_BNE);
            end

            ADDIEXEC: begin
                aluSrcA = 1;
                aluSrcB = 2'b10;
                aluOP = 2'b00;
            end

            ADDIWB: begin
                regWrite = 1;
                regDst = 2'b01;
            end

            JUMP: begin
                pcWrite = 1;
                pcSrc = 2'b10;
            end

            JALWB: begin
                regWrite = 1;
                regDst = 2'b10;
                jumpLink = 1;
            end

            LIEXEC: begin
                aluSrcA = 1'b0;
                aluSrcB = 2'b10;
                aluOP   = 2'b11;
            end

            LIWB: begin
                regWrite = 1'b1;
                regDst   = 2'b01;
            end

        endcase 
    end
 
endmodule

`endif
// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// Main Decoder
// =======================================================

`ifndef MAINDEC
`define MAINDEC

`timescale 1ns/100ps

import opcode_pkg::*;

module mainDecoder(
    input  logic [3:0] opcode,

    output logic       regWrite,
    output logic       memWrite,
    output logic       memToReg,
    output logic       aluSrc,
    output logic       branchEq,
    output logic       branchNe,
    output logic       jump,
    output logic       jumpLink,
    output logic       memBase,
    output logic       branchSrc,
    output logic [1:0] regDst,
    output logic [1:0] aluOP,
    output logic       flagWrite
);

    logic [14:0] controls;

    assign {
        regWrite, // 1: write to a register
        memWrite, // 1: write to memory (SW)
        memToReg, // 1: data from memory | 0: data from ALU (to the register)
        aluSrc,   // 1: use sign-extended imm | 0: register value
        branchEq, // 1: branch if equal
        branchNe, // 1: branch if not equal
        jump,     // 1: jump
        jumpLink, // 1: jump and Link (save return address $ra)
        regDst,   // 00: Accumulator | 01: rd field (I-type) | 10: R15 $ra
        aluOP,    // 00: add | 01: subtract | 10: function field
        memBase,  // 1: use R9 as ALU input (SW & LW)
        branchSrc,// 1: use R0 as ALU input (BEQ & BNE)
        flagWrite // 1: write to flag
    } = controls;

    always_comb begin
        case (opcode) // decode each opcode to corresponding control signals
            OP_RTYPE: controls = 15'b1_0_0_0_0_0_0_0_00_10_0_0_1;
            OP_ADDI:  controls = 15'b1_0_0_1_0_0_0_0_01_00_0_0_1;
            OP_LW:    controls = 15'b1_0_1_1_0_0_0_0_01_00_1_0_0;
            OP_SW:    controls = 15'b0_1_0_1_0_0_0_0_00_00_1_0_0;
            OP_BEQ:   controls = 15'b0_0_0_0_1_0_0_0_00_01_0_1_0;
            OP_BNE:   controls = 15'b0_0_0_0_0_1_0_0_00_01_0_1_0;
            OP_J:     controls = 15'b0_0_0_0_0_0_1_0_00_00_0_0_0;
            OP_JAL:   controls = 15'b1_0_0_0_0_0_1_1_10_00_0_0_0;

            default:  controls = 15'bxxxxxxxxxxxxxxx; // default case, invalid 
        endcase
    end
endmodule

`endif
// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// Memory (imem + dmem)
// =======================================================

`ifndef MEM
`define MEM

`timescale 1ns/100ps

module mem (
    input  logic         clk,
    input  logic         memWrite,
    input  logic [5:0]   address,
    input  logic [15:0]  writeData,

    output logic [15:0]  readData
);

    logic [15:0] RAM [0:63];

    initial begin
        integer i;
        for (i = 0; i < 64; i = i +1)
           RAM[i] = 16'b0; 
        $readmemh("../programs/program", RAM);
    end
        
    assign readData = RAM[address];

    always_ff @(posedge clk) begin
        if (memWrite)
            RAM[address] <= writeData;
    end

endmodule

`endif
// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// 2:1 mux 
// =======================================================

`ifndef MUX2
`define MUX2

`timescale 1ns/100ps

module mux2 #(parameter n = 16) (
    input   logic [n-1:0] d0,        //input 1 
    input   logic [n-1:0] d1,        //input 2
    input   logic        s,         //selection pin
    output  logic [n-1:0] data_out
);

   assign data_out = s ? d1 : d0;

endmodule

`endif
// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// 4:1 mux 
// =======================================================

`ifndef MUX4
`define MUX4

`timescale 1ns/100ps

module mux4 #(parameter n = 16)(
    input   logic [n-1:0] d0,
    input   logic [n-1:0] d1,
    input   logic [n-1:0] d2,
    input   logic [n-1:0] d3,
    input   logic [1:0]  s, //2bit selection pin
    output  logic [n-1:0] data_out
);

    logic [n-1:0] result_01;
    logic [n-1:0] result_23;

    mux2 #(n)u1(.d0(d0), .d1(d1), .s(s[0]), .data_out(result_01));
    mux2 #(n)u2(.d0(d2), .d1(d3), .s(s[0]), .data_out(result_23));

    mux2 #(n)u3(.d0(result_01), .d1(result_23), .s(s[1]), .data_out(data_out));

endmodule

`endif
// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// OPCODE and FUNCTION FIELD(for R-Type) is declared here.
// =======================================================

package opcode_pkg;
    // OPCODE
    parameter logic [3:0] OP_RTYPE  = 4'b0000; // R-type instructions use function field
    parameter logic [3:0] OP_ADDI   = 4'b0001; // add immediate

    parameter logic [3:0] OP_LW     = 4'b0010; // load word
    parameter logic [3:0] OP_SW     = 4'b0011; // store word
    /* because our ISA does not have enough room for rd and rs,
    *  LW and SW will be look as such:
    *
    *  LW rd, imm8
    *    R[rd] = MEM[R9 + signext(imm8)]
    *
    *  SW rd, imm8
    *    MEM[R9 + signext(imm8)] = R[rd]
    *
    *  --> Deviation from the proposal: I think dropping R10 to GEN or
    *  Reserved would be better
    *
    */

    parameter logic [3:0] OP_BEQ    = 4'b0100; // branch if equal
    parameter logic [3:0] OP_BNE    = 4'b0101; // branch not equal
    parameter logic [3:0] OP_J      = 4'b0110; // jump
    parameter logic [3:0] OP_JAL    = 4'b0111; // jump and link, R15 as $ra
    parameter logic [3:0] OP_LI     = 4'b1000;

/*  Unused for now
    parameter logic [3:0] OP_       = 4'b1001;
    parameter logic [3:0] OP_       = 4'b1010;
    parameter logic [3:0] OP_       = 4'b1011;
    parameter logic [3:0] OP_       = 4'b1100;
    parameter logic [3:0] OP_       = 4'b1101;
    parameter logic [3:0] OP_       = 4'b1110;
    parameter logic [3:0] OP_       = 4'b1111;
*/

    // FUNCTION FIELD for R-TYPE instructions
    // I made it so that it matches with aluCTRL signal to make my life easier
    parameter logic [3:0] R_AND     = 4'b0000; // AND
    parameter logic [3:0] R_OR      = 4'b0001; // OR
    parameter logic [3:0] R_ADD     = 4'b0010; // ADD
    parameter logic [3:0] R_NOR     = 4'b0011; // NOR
    parameter logic [3:0] R_MFLO    = 4'b0100; // MFLO
    parameter logic [3:0] R_MFHI    = 4'b0101; // MFHI
    parameter logic [3:0] R_SUB     = 4'b0110; // SUB
    parameter logic [3:0] R_SLT     = 4'b0111; // SLT
    parameter logic [3:0] R_XOR     = 4'b1000; // XOR
    parameter logic [3:0] R_SLL     = 4'b1001; // SLL
    parameter logic [3:0] R_SRL     = 4'b1010; // SRL
    parameter logic [3:0] R_MUL     = 4'b1011; // MUL (this saves things to HiLo, you need to load with MFLO or MFHI)
    parameter logic [3:0] R_PASSB   = 4'b1100;
/* Unused for now
    parameter logic [3:0] R_        = 4'b1101;
    parameter logic [3:0] R_        = 4'b1110;
    parameter logic [3:0] R_        = 4'b1111;
*/
endpackage
// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// register file 
// =======================================================

`ifndef REGFILE
`define REGFILE

`timescale 1ns/100ps

module registerFile(
    input logic        clk,
    input logic        writeEnable, // enable writing

    input logic [3:0]  readReg1,    // Firt reg to read
    input logic [3:0]  readReg2,    // Second reg to read
    input logic [3:0]  writeReg,    // Destination
    input logic [15:0] writeData,   // Data that's going to be stored in Destination

    output logic [15:0] readData1,  // output of readReg1
    output logic [15:0] readData2,  // output of readReg2

    input logic         flagWrite,
    input logic  [15:0] flagsData
);

    // creating registerFile
    // 16 of 16 bit register
    logic [15:0] registers [0:15];

    integer i;

    initial begin
        for (i = 0; i < 16; i = i + 1)
            registers[i] = 16'b0;
    end

    // Unlike MIPS, our Register 0 is Accumulator, so we should be able to
    // write on that register
    always_ff @(posedge clk) begin
        if (writeEnable)
            registers[writeReg] <= writeData;
        if (flagWrite)
            registers[12] <= flagsData;
    end

    assign readData1 = registers[readReg1];
    assign readData2 = registers[readReg2];

endmodule

`endif
// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// Sign Extension
// =======================================================

`ifndef SIGNEXTEND
`define SIGNEXTEND

`timescale 1ns/100ps

module signExtend(
    input logic  [7:0]   A,
    output logic [15:0]  Y
);
    assign Y = { {8{A[7]}}, A };

endmodule

`endif
// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// SL1
// =======================================================

`ifndef SL1
`define SL1

`timescale 1ns/100ps

module sl1(
    input  logic [15:0] A,
    output logic [15:0] Y
);
    assign Y = {A[14:0], 1'b0};
endmodule

`endif
`ifndef CPU
`define CPU

`timescale 1ns/100ps

`include "controller.sv"
`include "datapath.sv"
`include "hazard.sv"

module cpu (
    input  logic        clk, reset,
    input  logic [15:0] readData,

    output logic        memWrite,
    output logic [15:0] pc,
    output logic [15:0] aluOut,
    output logic [15:0] writeData,
    output logic [15:0] memAddress
);

    // ===================== CONTROLLER SIGNALS =====================
    logic        irWrite, mdrWrite, iord;
    logic        regWrite, memToReg, aluSrcA;
    logic        jumpLink, memBase, branchSrc;
    logic        flagWrite, pcEn, readRd;
    logic [1:0]  aluSrcB, regDst, pcSrc;
    logic [3:0]  aluCTRL;
    logic        zero;
    logic [15:0] instrOut;

    // ===================== HAZARD SIGNALS =====================
    logic        stall, flush_ifid, flush_idex;
    logic [3:0]  id_rs_out, id_rt_out;
    logic [3:0]  ex_writeReg_out;
    logic        ex_memRead_out, ex_regWrite_out;
    logic [3:0]  mem_writeReg_out;
    logic        mem_regWrite_out;
    logic        id_branch_out, id_jump_out;

    // memRead derived from opcode
    logic memRead;
    assign memRead = (instrOut[15:12] == 4'b0010); // OP_LW

    // memWrite comes only from datapath
    logic memWriteInternal;
    assign memWrite = memWriteInternal;

    // ===================== CONTROLLER =====================
    controller ctrl (
        .clk(clk),
        .reset(reset),
        .opcode(instrOut[15:12]),
        .funct(instrOut[3:0]),
        .zero(zero),
        .irWrite(irWrite),
        .mdrWrite(mdrWrite),
        .iord(iord),
        .memWrite(),            // not used directly — pipeline handles it
        .regWrite(regWrite),
        .memToReg(memToReg),
        .aluSrcA(aluSrcA),
        .regDst(regDst),
        .aluSrcB(aluSrcB),
        .pcSrc(pcSrc),
        .flagWrite(flagWrite),
        .jumpLink(jumpLink),
        .memBase(memBase),
        .branchSrc(branchSrc),
        .pcEn(pcEn),
        .aluCTRL(aluCTRL),
        .readRd(readRd)
    );

    // ===================== HAZARD UNIT =====================
    hazard haz (
        .id_rs(id_rs_out),
        .id_rt(id_rt_out),
        .ex_writeReg(ex_writeReg_out),
        .ex_memRead(ex_memRead_out),
        .ex_regWrite(ex_regWrite_out),
        .mem_writeReg(mem_writeReg_out),
        .mem_regWrite(mem_regWrite_out),
        .id_branch(id_branch_out),
        .id_jump(id_jump_out),
        .stall(stall),
        .flush_ifid(flush_ifid),
        .flush_idex(flush_idex)
    );

    // ===================== DATAPATH =====================
    datapath dp (
        .clk(clk),
        .reset(reset),
        .if_instr(instrOut),
        .regWrite(regWrite),
        .memToReg(memToReg),
        .memRead(memRead),
        .memWrite(memWrite),
        .aluSrc(aluSrcA),
        .jump(pcEn),
        .jumpLink(jumpLink),
        .memBase(memBase),
        .branchSrc(branchSrc),
        .flagWrite(flagWrite),
        .regDst(regDst),
        .aluCTRL(aluCTRL),
        .stall(stall),
        .flush_ifid(flush_ifid),
        .flush_idex(flush_idex),
        .readData(readData),
        .pc(pc),
        .aluOut(aluOut),
        .writeData(writeData),
        .memWriteOut(memWriteInternal),
        .dataAddress(memAddress),
        .instrOut(instrOut),
        .id_rs_out(id_rs_out),
        .id_rt_out(id_rt_out),
        .ex_writeReg_out(ex_writeReg_out),
        .ex_memRead_out(ex_memRead_out),
        .ex_regWrite_out(ex_regWrite_out),
        .mem_writeReg_out(mem_writeReg_out),
        .mem_regWrite_out(mem_regWrite_out),
        .id_branch_out(id_branch_out),
        .id_jump_out(id_jump_out),
        .zero_out(zero)
    );

endmodule

`endif`ifndef DATAPATH
`define DATAPATH

`timescale 1ns/100ps

`include "../src-multicycle/adder.sv"
`include "../src-multicycle/alu.sv"
`include "../src-multicycle/mux2.sv"
`include "../src-multicycle/mux4.sv"
`include "../src-multicycle/signExtend.sv"
`include "../src-multicycle/registerFile.sv"
`include "../src-multicycle/sl1.sv"
`include "dff.sv"
`include "if_id_reg.sv"
`include "id_ex_reg.sv"
`include "ex_mem_reg.sv"
`include "mem_wb_reg.sv"

module datapath (
    input  logic        clk, reset,

    input  logic [15:0] if_instr,

    input  logic        regWrite,
    input  logic        memToReg,
    input  logic        memRead,
    input  logic        memWrite,
    input  logic        aluSrc,
    input  logic        jump,
    input  logic        jumpLink,
    input  logic        memBase,
    input  logic        branchSrc,
    input  logic        flagWrite,
    input  logic [1:0]  regDst,
    input  logic [3:0]  aluCTRL,

    // hazard unit
    input  logic        stall,
    input  logic        flush_ifid,
    input  logic        flush_idex,

    // from memory
    input  logic [15:0] readData,

    output logic [15:0] instrOut,
    output logic [15:0] pc,
    output logic [15:0] aluOut,
    output logic [15:0] writeData,
    output logic        memWriteOut,
    output logic [15:0] dataAddress,

    output logic [3:0]  id_rs_out,
    output logic [3:0]  id_rt_out,
    output logic [3:0]  ex_writeReg_out,
    output logic        ex_memRead_out,
    output logic        ex_regWrite_out,
    output logic [3:0]  mem_writeReg_out,
    output logic        mem_regWrite_out,
    output logic        id_branch_out,
    output logic        id_jump_out,
    output logic        zero_out
);

// ===================== IF STAGE =====================
    logic [15:0] pcNext;
    logic [15:0] pcPlus2;    


    dff #(16) pcReg (
        .clk(clk),
        .reset(reset),
        .enable(~stall),    
        .flush(1'b0),       
        .D(pcNext),
        .Q(pc)
    );

  
    adder pcAdd (.A(pc), .B(16'd2), .Y(pcPlus2));
    // ===================== IF/ID REGISTER =====================
    logic [15:0] id_pc_plus2;
    logic [15:0] id_instr;

    if_id_reg ifid (
        .clk(clk),
        .reset(reset),
        .enable(~stall),
        .flush(flush_ifid),
        .if_pc_plus2(pcPlus2),
        .if_instr(if_instr),
        .id_pc_plus2(id_pc_plus2),
        .id_instr(id_instr)
    );

    // ===================== ID STAGE =====================
    // register file read
    logic [3:0]  id_rs, id_rt, id_rd;
    logic [15:0] id_readData1, id_readData2;
    logic [15:0] id_signImm, id_signImmSh;
    logic [15:0] id_pcBranch;
    logic [15:0] wb_result;     // writeback result 

    // decode register fields from instruction
    // rs: readReg1 — R9 for LW/SW, R0 for branch, else instr[7:4]
    mux4 #(4) rsMux(
        id_instr[7:4],  // 00: normal rs
        4'd9,           // 01: R9 for LW/SW 
        4'd0,           // 10: R0 for branch
        4'd0,           // 11: unused
        {branchSrc, memBase},
        id_rs
    );

    assign id_rt = id_instr[11:8];  // rt is always instr[11:8]
    assign id_rd = id_instr[11:8];  // rd same field for I-type

    // register file — write comes from WB stage
    registerFile rf (
        .clk(clk),
        .writeEnable(wb_regWrite),     
        .readReg1(id_rs),
        .readReg2(id_rt),
        .writeReg(wb_writeReg),         
        .writeData(wb_result),          
        .readData1(id_readData1),
        .readData2(id_readData2),
        .flagWrite(wb_flagWrite),       
        .flagsData(wb_flagsData)        
    );

    // sign extend immediate
    signExtend se (.A(id_instr[7:0]), .Y(id_signImm));
    sl1 immSh (.A(id_signImm), .Y(id_signImmSh));

    // branch target = PC+2 + signImmSh
    adder branchAdd (.A(id_pc_plus2), .B(id_signImmSh), .Y(id_pcBranch));

    // branch/jump signals decoded from opcode
    logic id_branch, id_jump;
    assign id_branch = (id_instr[15:12] == 4'b0100) | 
                       (id_instr[15:12] == 4'b0101); // BEQ or BNE
    assign id_jump   = (id_instr[15:12] == 4'b0110) | 
                       (id_instr[15:12] == 4'b0111); // J or JAL

// ===================== ID/EX REGISTER =====================
    logic [15:0] ex_pc_plus2;
    logic        ex_regWrite, ex_memWrite, ex_memToReg;
    logic        ex_memRead, ex_aluSrc, ex_jump;
    logic        ex_jumpLink, ex_memBase, ex_branchSrc, ex_flagWrite;
    logic [1:0]  ex_regDst;
    logic [3:0]  ex_aluCTRL;
    logic [15:0] ex_readData1, ex_readData2, ex_signImm;
    logic [3:0]  ex_rs, ex_rt, ex_rd;

    id_ex_reg idex (
        .clk(clk),
        .reset(reset),
        .enable(~stall),
        .flush(flush_idex),
        .id_pc_plus2(id_pc_plus2),
        .id_regWrite(regWrite),
        .id_memWrite(memWrite),
        .id_memToReg(memToReg),
        .id_memRead(memRead),
        .id_aluSrc(aluSrc),
        .id_jump(jump),
        .id_jumpLink(jumpLink),
        .id_memBase(memBase),
        .id_branchSrc(branchSrc),
        .id_flagWrite(flagWrite),
        .id_regDst(regDst),
        .id_aluCTRL(aluCTRL),
        .id_readData1(id_readData1),
        .id_readData2(id_readData2),
        .id_signImm(id_signImm),
        .id_rs(id_rs),
        .id_rt(id_rt),
        .id_rd(id_rd),
        .ex_pc_plus2(ex_pc_plus2),
        .ex_regWrite(ex_regWrite),
        .ex_memWrite(ex_memWrite),
        .ex_memToReg(ex_memToReg),
        .ex_memRead(ex_memRead),
        .ex_aluSrc(ex_aluSrc),
        .ex_jump(ex_jump),
        .ex_jumpLink(ex_jumpLink),
        .ex_memBase(ex_memBase),
        .ex_branchSrc(ex_branchSrc),
        .ex_flagWrite(ex_flagWrite),
        .ex_regDst(ex_regDst),
        .ex_aluCTRL(ex_aluCTRL),
        .ex_readData1(ex_readData1),
        .ex_readData2(ex_readData2),
        .ex_signImm(ex_signImm),
        .ex_rs(ex_rs),
        .ex_rt(ex_rt),
        .ex_rd(ex_rd)
    );

    // ===================== EX STAGE =====================
    logic [15:0] ex_srcA, ex_srcB;
    logic [15:0] ex_aluOut;
    logic        ex_zero, ex_negative, ex_carry, ex_overflow;
    logic [3:0]  ex_writeReg;
    logic [15:0] ex_forwardA, ex_forwardB;

    // ---- forwarding muxes ----
    // 00: from register file
    // 01: forward from MEM/WB
    // 10: forward from EX/MEM
    logic [1:0] fwdA, fwdB;

    assign fwdA = (mem_regWrite && (mem_writeReg == ex_rs)) ? 2'b10 :
                  (wb_regWrite  && (wb_writeReg  == ex_rs)) ? 2'b01 :
                  2'b00;

    assign fwdB = (mem_regWrite && (mem_writeReg == ex_rt)) ? 2'b10 :
                  (wb_regWrite  && (wb_writeReg  == ex_rt)) ? 2'b01 :
                  2'b00;

    // 3-way mux for srcA
    always_comb begin
        case (fwdA)
            2'b00:   ex_forwardA = ex_readData1;        // from reg file
            2'b01:   ex_forwardA = wb_result;           // from WB
            2'b10:   ex_forwardA = mem_aluOut;          // from EX/MEM
            default: ex_forwardA = ex_readData1;
        endcase
    end

    // 3-way mux for srcB
    always_comb begin
        case (fwdB)
            2'b00:   ex_forwardB = ex_readData2;        // from reg file
            2'b01:   ex_forwardB = wb_result;           // from WB
            2'b10:   ex_forwardB = mem_aluOut;          // from EX/MEM
            default: ex_forwardB = ex_readData2;
        endcase
    end

    // srcA: ADDI special case
    assign ex_srcA = ex_forwardA;

    // srcB: forwarded register or sign extended immediate
    mux2 #(16) srcBMux (ex_forwardB, ex_signImm, ex_aluSrc, ex_srcB);

    // ALU
    alu aluUnit (
        .clk(clk),
        .a(ex_srcA),
        .b(ex_srcB),
        .aluCTRL(ex_aluCTRL),
        .result(ex_aluOut),
        .zero(ex_zero),
        .negative(ex_negative),
        .carry(ex_carry),
        .overflow(ex_overflow)
    );

    // compute writeReg from regDst
    
    mux4 #(4) wrMux (
        4'd0,           // 00: accumulator
        ex_rd,          // 01: I-type destination
        4'd15,          // 10: $ra for JAL
        4'd0,           // 11: not used
        ex_regDst,
        ex_writeReg
    );

    // j target
    logic [15:0] ex_pcJump;
    assign ex_pcJump = {ex_pc_plus2[15:13], ex_rd, ex_rt, ex_signImm[0], 1'b0};
    // ===================== EX/MEM REGISTER =====================
    logic [15:0] mem_aluOut;
    logic [15:0] mem_writeData;
    logic [3:0]  mem_writeReg;
    logic        mem_regWrite, mem_memWrite, mem_memToReg;
    logic        mem_memRead, mem_flagWrite;

    ex_mem_reg exmem (
        .clk(clk),
        .reset(reset),
        .enable(1'b1),         
        .flush(1'b0),           
        .ex_aluOut(ex_aluOut),
        .ex_writeData(ex_forwardB),  
        .ex_writeReg(ex_writeReg),
        .ex_regWrite(ex_regWrite),
        .ex_memWrite(ex_memWrite),
        .ex_memToReg(ex_memToReg),
        .ex_memRead(ex_memRead),
        .ex_flagWrite(ex_flagWrite),
        .mem_aluOut(mem_aluOut),
        .mem_writeData(mem_writeData),
        .mem_writeReg(mem_writeReg),
        .mem_regWrite(mem_regWrite),
        .mem_memWrite(mem_memWrite),
        .mem_memToReg(mem_memToReg),
        .mem_memRead(mem_memRead),
        .mem_flagWrite(mem_flagWrite)
    );

    // ===================== MEM STAGE =====================
    assign dataAddress = mem_aluOut;
    assign writeData   = mem_writeData;
    assign memWriteOut = mem_memWrite;
// ===================== MEM/WB REGISTER =====================
    logic [15:0] wb_aluOut;
    logic [15:0] wb_readData;
    logic [3:0]  wb_writeReg;
    logic        wb_regWrite, wb_memToReg, wb_flagWrite;

    mem_wb_reg memwb (
        .clk(clk),
        .reset(reset),
        .enable(1'b1),         
        .flush(1'b0),          
        .mem_aluOut(mem_aluOut),
        .mem_readData(readData),
        .mem_writeReg(mem_writeReg),
        .mem_regWrite(mem_regWrite),
        .mem_memToReg(mem_memToReg),
        .mem_flagWrite(mem_flagWrite),
        .wb_aluOut(wb_aluOut),
        .wb_readData(wb_readData),
        .wb_writeReg(wb_writeReg),
        .wb_regWrite(wb_regWrite),
        .wb_memToReg(wb_memToReg),
        .wb_flagWrite(wb_flagWrite)
    );

    // ===================== WB STAGE =====================
    logic [15:0] wb_aluOrMem;
    mux2 #(16) resultMux (
        wb_aluOut,
        wb_readData,
        wb_memToReg,
        wb_aluOrMem
    );

    // JAL: save PC+2 as return address instead of ALU result
    mux2 #(16) jalMux (
        wb_aluOrMem,
        ex_pc_plus2,        
        ex_jumpLink,        
        wb_result
    );

    // flags data for register file
    logic [15:0] wb_flagsData;
    assign wb_flagsData = {12'b0, ex_overflow, ex_carry, ex_negative, ex_zero};

    // ===================== PC NEXT LOGIC =====================
    // decide what PC becomes next cycle
    logic [15:0] pcNextBr;

    
    mux2 #(16) pcBrMux (
        pcPlus2,
        id_pcBranch,
        (ex_zero & ex_branchSrc),   
        pcNextBr
    );

   
    mux2 #(16) pcMux (
        pcNextBr,
        ex_pcJump,
        ex_jump,
        pcNext
    );

 
    assign aluOut = ex_aluOut;
    assign instrOut = id_instr;
    assign id_rs_out        = id_rs;
    assign id_rt_out        = id_rt;
    assign ex_writeReg_out  = ex_writeReg;
    assign ex_memRead_out   = ex_memRead;
    assign ex_regWrite_out  = ex_regWrite;
    assign mem_writeReg_out = mem_writeReg;
    assign mem_regWrite_out = mem_regWrite;
    assign id_branch_out    = id_branch;
    assign id_jump_out      = id_jump;
    assign zero_out         = ex_zero;
endmodule

`endif`ifndef dff
`define dff

`timescale 1ns/100ps

module dff #(parameter WIDTH = 16) (
    input logic         clk,
    input logic         reset,
    input logic         enable,
    input logic         flush,
    input logic [WIDTH-1:0] D,
    output logic [WIDTH-1:0] Q
);
    always_ff @(posedge clk) begin
        if (reset | flush)
            Q <= {WIDTH{1'b0}};
        else if (enable)
            Q <= D;
    end
endmodule

`endif`ifndef EX_MEM_REG
`define EX_MEM_REG

`timescale 1ns/100ps
`include "dff.sv"

module ex_mem_reg (
    input logic         clk,
    input logic         reset,
    input logic         enable,
    input logic         flush,
// data form ex stage
    input logic [15:0] ex_aluOut,
    input logic [15:0] ex_writeData,
    input logic [3:0]  ex_writeReg,

//control singnals that mem/wb will need
    input logic         ex_regWrite,
    input logic         ex_memWrite,
    input logic         ex_memToReg,
    input logic         ex_memRead,
    input logic         ex_flagWrite,

    //outputs to mem stage

    output logic [15:0] mem_aluOut,
    output logic [15:0] mem_writeData,
    output logic [3:0]  mem_writeReg,

    output logic        mem_regWrite,
    output logic        mem_memWrite,
    output logic        mem_memToReg,
    output logic        mem_memRead,
    output logic        mem_flagWrite
);

//data
    dff #(16) alu_reg  (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(ex_aluOut),    .Q(mem_aluOut));
    dff #(16) wd_reg   (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(ex_writeData), .Q(mem_writeData));
//register tag
    dff #(4)  wreg_reg (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(ex_writeReg),  .Q(mem_writeReg));
//ctrl signals
    dff #(1)  regw_reg (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(ex_regWrite),  .Q(mem_regWrite));
    dff #(1)  memw_reg (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(ex_memWrite),  .Q(mem_memWrite));
    dff #(1)  memt_reg (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(ex_memToReg),  .Q(mem_memToReg));
    dff #(1)  memr_reg (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(ex_memRead),   .Q(mem_memRead));
    dff #(1)  flagw_reg(.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(ex_flagWrite), .Q(mem_flagWrite));

endmodule 

`endif`ifndef HAZARD
`define HAZARD

`timescale 1ns/100ps

module hazard (
    input logic [3:0] id_rs,
    input logic [3:0] id_rt,

    input logic [3:0] ex_writeReg,  //destination of instruciton in EX
    input logic       ex_memRead,   // is Ex stage a lw
    input logic       ex_regWrite,  //does ex stage write a register?

    input logic [3:0] mem_writeReg, //destination of instrucion in mem
    input logic       mem_regWrite, //does MEM stage write a register

    input logic       id_branch, //BEQ or BNE in ID
    input logic       id_jump,   //J or JAL in ID


    output logic      stall,     
    output logic      flush_ifid,
    output logic      flush_idex
);

logic load_use_hazard;
assign load_use_hazard = ex_memRead &
                         ((ex_writeReg == id_rs) |
                           (ex_writeReg == id_rt));

logic branch_hazard;
logic jump_hazard;
assign branch_hazard = id_branch;
assign jump_hazard   = id_jump;

logic fwd_ex_rs, fwd_ex_rt;
assign fwd_ex_rs = ex_regWrite & (ex_writeReg != 4'd0) &
                   (ex_writeReg == id_rs);
assign fwd_ex_rt = ex_regWrite & (ex_writeReg != 4'd0) &
                   (ex_writeReg == id_rt);

logic fwd_mem_rs, fwd_mem_rt;
assign fwd_mem_rs = mem_regWrite & (mem_writeReg != 4'd0) &
                    (mem_writeReg == id_rs);
assign fwd_mem_rt = mem_regWrite & (mem_writeReg != 4'd0) &
                    (mem_writeReg == id_rt);

assign stall      = load_use_hazard;

assign flush_ifid = branch_hazard | jump_hazard;
assign flush_idex = branch_hazard;

endmodule

`endif`ifndef ID_EX_REG
`define ID_EX_REG

`timescale 1ns/100ps
`include "dff.sv"

module id_ex_reg(
    input logic         clk,
    input logic         reset,
    input logic         enable,
    input logic         flush,
    
    input logic[15:0]   id_pc_plus2, //pc
    //control signals form controller
    input logic         id_regWrite,
    input logic         id_memWrite,
    input logic         id_memToReg,
    input logic         id_memRead,
    input logic         id_aluSrc,
    input logic         id_jump,
    input logic         id_jumpLink,
    input logic         id_memBase,
    input logic         id_branchSrc,
    input logic         id_flagWrite,
    input logic [1:0]   id_regDst,
    input logic [3:0]   id_aluCTRL,

    //id data
    input logic [15:0]  id_readData1,
    input logic [15:0]  id_readData2,
    input logic [15:0]  id_signImm,

    //regtags for fowarding and write back
    input logic [3:0]   id_rs,
    input logic [3:0]   id_rt,
    input logic [3:0]   id_rd,
    //output to ex
    output logic [15:0] ex_pc_plus2,

    output logic         ex_regWrite,
    output logic         ex_memWrite,
    output logic         ex_memToReg,
    output logic        ex_memRead,
    output logic         ex_aluSrc,
    output logic         ex_jump,
    output logic         ex_jumpLink,
    output logic         ex_memBase,
    output logic         ex_branchSrc,
    output logic         ex_flagWrite,
    output logic [1:0]   ex_regDst,
    output logic [3:0]   ex_aluCTRL, 

    output logic [15:0]  ex_readData1,
    output logic [15:0]  ex_readData2, 
    output logic [15:0]  ex_signImm,

    output logic [3:0]   ex_rs,
    output logic [3:0]   ex_rt,
    output logic [3:0]   ex_rd
);
    // PC
    dff #(16) pc_reg      (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(id_pc_plus2),   .Q(ex_pc_plus2));

    // data
    dff #(16) rd1_reg     (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(id_readData1),  .Q(ex_readData1));
    dff #(16) rd2_reg     (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(id_readData2),  .Q(ex_readData2));
    dff #(16) simm_reg    (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(id_signImm),    .Q(ex_signImm));

    // register tags 
    dff #(4)  rs_reg      (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(id_rs),         .Q(ex_rs));
    dff #(4)  rt_reg      (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(id_rt),         .Q(ex_rt));
    dff #(4)  rd_reg      (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(id_rd),         .Q(ex_rd));

    // control signals 
    dff #(1)  regw_reg    (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(id_regWrite),   .Q(ex_regWrite));
    dff #(1)  memw_reg    (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(id_memWrite),   .Q(ex_memWrite));
    dff #(1)  memtr_reg   (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(id_memToReg),   .Q(ex_memToReg));
    dff #(1)  memrd_reg   (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(id_memRead),    .Q(ex_memRead));
    dff #(1)  alus_reg    (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(id_aluSrc),     .Q(ex_aluSrc));
    dff #(1)  jmp_reg     (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(id_jump),       .Q(ex_jump));
    dff #(1)  jmpl_reg    (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(id_jumpLink),   .Q(ex_jumpLink));
    dff #(1)  memb_reg    (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(id_memBase),    .Q(ex_memBase));
    dff #(1)  bsrc_reg    (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(id_branchSrc),  .Q(ex_branchSrc));
    dff #(1)  flagw_reg   (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(id_flagWrite),  .Q(ex_flagWrite));

    // 2-bit control signals
    dff #(2)  rdst_reg    (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(id_regDst),     .Q(ex_regDst));

    // 4-bit control signals 
    dff #(4)  aluc_reg    (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(id_aluCTRL),    .Q(ex_aluCTRL));

endmodule

`endif
`ifndef IF_ID_REG
`define IF_ID_REG

`timescale 1ns/100ps
`include "dff.sv"
module if_id_reg (
    input logic         clk,
    input logic         reset,
    input logic         enable, //0 - stall
    input logic         flush, //1 = inject bubble
//inputs fromm IF stage
input logic [15:0] if_pc_plus2,
input logic [15:0] if_instr,

//outputs
output logic [15:0] id_pc_plus2,
output logic [15:0] id_instr
);

dff #(16) pc_reg(//register that store pc +2
    .clk(clk),
    .reset(reset),
    .enable(enable),
    .flush(flush),
    .D(if_pc_plus2),
    .Q(id_pc_plus2)
);
dff #(16) instr_reg(
    .clk(clk),
    .reset(reset),
    .enable(enable),
    .flush(flush),
    .D(if_instr),
    .Q(id_instr)
);

endmodule

`endif`ifndef MEM_WB_REG
`define MEM_WB_REG

`timescale 1ns/100ps
`include "dff.sv"

module mem_wb_reg(
    input logic     clk,
    input logic     reset,
    input logic     enable,
    input logic     flush,

    input logic [15:0] mem_aluOut,
    input logic [15:0] mem_readData,
    input logic [3:0]  mem_writeReg,

    input logic     mem_regWrite,
    input logic     mem_memToReg,
    input logic     mem_flagWrite,

    output logic [15:0] wb_aluOut,
    output logic [15:0] wb_readData,
    output logic [3:0]  wb_writeReg,
    output logic        wb_regWrite,
    output logic        wb_memToReg,
    output logic        wb_flagWrite
);
//data
    dff #(16) alu_reg  (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(mem_aluOut),    .Q(wb_aluOut));
    dff #(16) rd_reg   (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(mem_readData),  .Q(wb_readData));
//reg tag
    dff #(4)  wreg_reg (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(mem_writeReg),  .Q(wb_writeReg));
//ctrl signals
    dff #(1)  regw_reg (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(mem_regWrite),  .Q(wb_regWrite));
    dff #(1)  memt_reg (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(mem_memToReg),  .Q(wb_memToReg));
    dff #(1)  flagw_reg(.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(mem_flagWrite), .Q(wb_flagWrite));
endmodule

`endif