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
