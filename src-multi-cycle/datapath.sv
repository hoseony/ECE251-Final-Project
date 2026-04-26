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

    input  logic           regWrite,
    input  logic           memToReg, 
    input  logic           pcSrc,
    input  logic           aluSrc,
    input  logic           jump,
    input  logic           jumpLink,
    input  logic           memBase,
    input  logic           branchSrc,
    input  logic [1:0]     regDst,
    input  logic [3:0]     aluCTRL,
    input  logic           flagWrite,

    input  logic [15:0]    instr,
    input  logic [15:0]    readData,

    output logic           zero,
    output logic [15:0]    pc,
    output logic [15:0]    aluOut,
    output logic [15:0]    writeData
);
    // ====================== Internal Signals ========================
    logic [15:0] pcNext, pcNextBr, pcPlus2, pcBranch, pcJump;
    logic [15:0] signImm, signImmSh;

    logic [3:0]  readReg1, readReg2;
    logic [3:0]  writeReg;

    logic [15:0] readData1, readData2;
    logic [15:0] srcA, srcB;            // ALU input

    logic [15:0] aluOrMem;
    logic [15:0] result;

    logic negative, carry, overflow;

    // ======================PC Logic ========================

    dff pcReg(.clk(clk), .r(reset), .D(pcNext), .Q(pc));

    // byte addressable
    adder           pcP1(.A(pc), .B(16'b10), .Y(pcPlus2));
    signExtend      se(.A(instr[7:0]), .Y(signImm));
    sl1             immsh(.A(signImm), .Y(signImmSh)); // we only need shift left 1 since its 2 byte per instruction
    adder           pcAdd2(pcPlus2, signImmSh, pcBranch);

    // pcSrc: 0 --> pcNextBr = pcPlus2 | pcSrc: 1 --> pcNextBr = pcBranch
    mux2      #(16) pcbrmux(pcPlus2, pcBranch, pcSrc, pcNextBr); 

    // jump: 0 --> pcNext = pcPlus2 | jump: 1 --> pcNext = upper3bit of PC+2
    // + 12bit (address form instruction) + 0 ending (make sure it is addressed)
    assign pcJump = {pcPlus2[15:13], instr[11:0], 1'b0};
    mux2      #(16) pcmux(pcNextBr, pcJump, jump, pcNext);

    // ======================Register File ========================

    // ALU inputA |            rs(R-Type), R9: memory pointer, R0: accumulator
    mux4      #(4)  readRegMux(instr[7:4], 4'd9, 4'd0, 4'd0, {branchSrc, memBase}, readReg1);

    // ALU inputB | R-Type rt, I-Type rd
    assign readReg2 = instr[11:8];

    // Destination 
    // Remember from mainDecoder:
    // regDst [1:0], 00: Accumulator | 01: rd field (I-type) | 10: R15 $ra
    mux4      #(4)  wrMux(4'd0, instr[11:8], 4'd15, 4'd0, regDst, writeReg);

    // for now, always update flag
    logic [15:0] flagsData;
    assign flagsData = {12'b0, overflow, carry, negative, zero};

    registerFile    rf(clk, regWrite, readReg1, readReg2, writeReg, result, readData1, readData2, flagWrite, flagsData);

    // ======================ALU logic ========================

    assign srcA = (instr[15:12] == 4'b0001) ? 16'b0 : readData1;

    // Again, remember from mainDecoder 
    // aluSrc 1: sign extend, 0: registre
    mux2      #(16) srcBMux(readData2, signImm, aluSrc, srcB);
    alu             aluUnit(clk, srcA, srcB, aluCTRL, aluOut, zero, negative, carry, overflow);
    
    assign writeData = readData2;
    mux2      #(16) resultMux(aluOut, readData, memToReg, aluOrMem);
    mux2      #(16) jalMux(aluOrMem, pcPlus2, jumpLink, result);
endmodule

`endif
