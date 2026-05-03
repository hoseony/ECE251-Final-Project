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
`include "hazard.sv"

module cpu(
    input  logic        clk, reset, Exception_Flag,
    
    output logic [15:0] pcF,
    input  logic [15:0] instrF,

    output logic        memwriteM,
    output logic [15:0] aluoutM, writedataM,
    input  logic [15:0] readdataM
);

    logic        regwriteD, memwriteD, memtoregD;
    logic        alusrcD;
    logic [1:0]  regdstD;
    logic        branchD, branchneD;
    logic        jumpD, jumplinkD;
    logic        membaseD, branchsrcD;
    logic        flagwriteD;
    logic [3:0]  alucontrolD;

    logic        stallF, stallD, stallE, stallM, stallW;
    logic        flushD, flushE;
    logic        forwardaD, forwardbD;
    logic [1:0]  forwardaE, forwardbE;
    logic [3:0]  rsD, rtD, rsE, rtE;
    logic [3:0]  writeregE, writeregM, writeregW;
    logic        regwriteE, regwriteM, regwriteW;
    logic        memtoregE, memtoregM;
    logic [15:0] instrD;

    controller ctrl(
        .op(instrD[15:12]),      // opcode field
        .funct(instrD[3:0]),     // funct field (R-type)
        .regWrite(regwriteD),
        .memWrite(memwriteD),
        .memToReg(memtoregD),
        .aluSrc(alusrcD),
        .regDst(regdstD),
        .aluOP(),                // consumed internally by aluDecoder
        .branch(branchD),
        .branchNe(branchneD),
        .jump(jumpD),
        .jumpLink(jumplinkD),
        .memBase(membaseD),
        .branchSrc(branchsrcD),
        .flagWrite(flagwriteD),
        .aluCTRL(alucontrolD)
    );

    datapath dp(
        .clk(clk), .reset(reset),
        .pcF(pcF), .instrF(instrF),
        .aluoutM(aluoutM), .writedataM(writedataM),
        .readdataM(readdataM), .memwriteM_out(memwriteM),
        .regwriteD(regwriteD), .memwriteD(memwriteD), .memtoregD(memtoregD),
        .alusrcD(alusrcD), .regdstD(regdstD),
        .branchD(branchD), .branchneD(branchneD),
        .jumpD(jumpD), .jumplinkD(jumplinkD),
        .membaseD(membaseD), .branchsrcD(branchsrcD),
        .flagwriteD(flagwriteD), .alucontrolD(alucontrolD),
        .instrD(instrD),
        .stallF(stallF), .stallD(stallD), .stallE(stallE),
        .stallM(stallM), .stallW(stallW),
        .flushD(flushD), .flushE(flushE),
        .forwardaD(forwardaD), .forwardbD(forwardbD),
        .forwardaE(forwardaE), .forwardbE(forwardbE),
        .rsD(rsD), .rtD(rtD), .rsE(rsE), .rtE(rtE),
        .writeregE(writeregE), .writeregM(writeregM), .writeregW(writeregW),
        .regwriteE(regwriteE), .regwriteM(regwriteM), .regwriteW(regwriteW),
        .memtoregE(memtoregE), .memtoregM(memtoregM),
        .Exception_Flag(Exception_Flag)
    );

    hazard hu(
        .rsD(rsD), .rtD(rtD), .rsE(rsE), .rtE(rtE),
        .writeregE(writeregE), .writeregM(writeregM), .writeregW(writeregW),
        .regwriteE(regwriteE), .regwriteM(regwriteM), .regwriteW(regwriteW),
        .memtoregE(memtoregE), .memtoregM(memtoregM),
        .branchD(branchD), .branchneD(branchneD),
        .Exception_Flag(Exception_Flag),
        .forwardaD(forwardaD), .forwardbD(forwardbD),
        .forwardaE(forwardaE), .forwardbE(forwardbE),
        .stallF(stallF), .stallD(stallD), .stallE(stallE),
        .stallM(stallM), .stallW(stallW),
        .flushD(flushD), .flushE(flushE)
    );

endmodule

`endif
