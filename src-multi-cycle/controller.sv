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

module controller(
    input  logic [3:0] opcode,
    input  logic [3:0] funct,
    input  logic       zero,

    output logic       regWrite,
    output logic       memWrite,
    output logic       memToReg,
    output logic       pcSrc,
    output logic       aluSrc,
    output logic       jump,
    output logic       jumpLink,
    output logic       memBase,
    output logic       branchSrc,
    output logic [1:0] regDst,
    output logic [3:0] aluCTRL,
    output logic       flagWrite
);

    logic [1:0] aluOP;
    logic branchEq, branchNe;

    mainDecoder md(
        .opcode(opcode),
        .regWrite(regWrite),
        .memWrite(memWrite),
        .memToReg(memToReg),
        .aluSrc(aluSrc),
        .branchEq(branchEq),
        .branchNe(branchNe),
        .jump(jump),
        .jumpLink(jumpLink),
        .memBase(memBase),
        .branchSrc(branchSrc),
        .regDst(regDst),
        .aluOP(aluOP),
        .flagWrite(flagWrite)
    );

    // aluOP from mainDecoder --> aluDecoder
    
    aluDecoder ad(
        .aluOP(aluOP),
        .funct(funct),
        .aluCTRL(aluCTRL)
    );

    assign pcSrc = (branchEq & zero) | (branchNe & ~zero);
endmodule

`endif
