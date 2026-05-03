// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// Controller
// =======================================================

`ifndef CTRL
`define CTRL

`timescale 1ns/100ps

`include "mainDecoder.sv"
`include "aluDecoder.sv"

module controller(
    input  logic [3:0] op,
    input  logic [3:0] funct,

    output logic       regWrite,
    output logic       memWrite,
    output logic       memToReg,
    output logic       aluSrc,
    output logic [1:0] regDst,
    output logic [1:0] aluOP,
    output logic       branch,
    output logic       branchNe,
    output logic       jump,
    output logic       jumpLink,
    output logic       memBase,
    output logic       branchSrc,
    output logic       flagWrite,
    output logic [3:0] aluCTRL
);

    maindec md(
        .op(op),
        .regWrite(regWrite),
        .memWrite(memWrite),
        .memToReg(memToReg),
        .aluSrc(aluSrc),
        .regDst(regDst),
        .aluOP(aluOP),
        .branch(branch),
        .branchNe(branchNe),
        .jump(jump),
        .jumpLink(jumpLink),
        .memBase(memBase),
        .branchSrc(branchSrc),
        .flagWrite(flagWrite)
    );

    aluDecoder ad(
        .op(op),
        .aluOP(aluOP),
        .funct(funct),
        .aluCTRL(aluCTRL)
    );

endmodule
`endif
