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
