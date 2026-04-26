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
