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

`endif