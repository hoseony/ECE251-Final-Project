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

    input  logic [15:0] instr,
    input  logic [15:0] readData,

    output  logic        memWrite,
    output  logic [15:0] pc,
    output  logic [15:0] aluOut,
    output  logic [15:0] writeData
);
    // send help...
    logic           regWrite;
    logic           memToReg; 
    logic           pcSrc;
    logic           aluSrc;
    logic           jump;
    logic           jumpLink;
    logic           memBase;
    logic           branchSrc;
    logic [1:0]     regDst;
    logic [3:0]     aluCTRL;
    logic           zero;
    logic           flagWrite;

    controller ctrl(
        .opcode(instr[15:12]),
        .funct(instr[3:0]),
        .zero(zero),
        .regWrite(regWrite),
        .memWrite(memWrite),
        .memToReg(memToReg),
        .pcSrc(pcSrc),
        .aluSrc(aluSrc),
        .jump(jump),
        .jumpLink(jumpLink),
        .memBase(memBase),
        .branchSrc(branchSrc),
        .regDst(regDst),
        .aluCTRL(aluCTRL),
        .flagWrite(flagWrite)
    );

    datapath dp(
        .clk(clk),
        .reset(reset),
        .regWrite(regWrite),
        .memToReg(memToReg),
        .pcSrc(pcSrc),
        .aluSrc(aluSrc),
        .jump(jump),
        .jumpLink(jumpLink),
        .memBase(memBase),
        .branchSrc(branchSrc),
        .regDst(regDst),
        .aluCTRL(aluCTRL),
        .instr(instr),
        .readData(readData),
        .zero(zero),
        .pc(pc),
        .aluOut(aluOut),
        .writeData(writeData),
        .flagWrite(flagWrite)
    );

endmodule

`endif
