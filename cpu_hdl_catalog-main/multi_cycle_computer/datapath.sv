//////////////////////////////////////////////////////////////////////////////////
// The Cooper Union
// ECE 251 Spring 2023
// Engineer: Prof Rob Marano
// 
//     Create Date: 2023-02-07
//     Module Name: datapath
//     Description: 32-bit Multi-cycle MIPS Datapath
//
//////////////////////////////////////////////////////////////////////////////////
`ifndef DATAPATH
`define DATAPATH

`timescale 1ns/100ps

`include "regfile.sv"
`include "alu.sv"
`include "dff.sv"
`include "flopenr.sv"
`include "adder.sv"
`include "sl2.sv"
`include "mux2.sv"
`include "mux3.sv"
`include "mux4.sv"
`include "signext.sv"

module datapath
    #(parameter n = 32)(
    input  logic        clk, reset,
    input  logic        pcen, irwrite, regwrite,
    input  logic        alusrca, iord, memtoreg, regdst,
    input  logic [1:0]  alusrcb, pcsource,
    input  logic [3:0]  alucontrol,
    output logic        zero,
    output logic [5:0]  op, funct,
    output logic [(n-1):0] adr, writedata,
    input  logic [(n-1):0] readdata
);
    // Intermediate registers
    logic [(n-1):0] pc, ir, mdr, a, b, aluout;
    logic [(n-1):0] pcnext;
    logic [(n-1):0] rd1, rd2;
    logic [(n-1):0] signimm, signimmsh;
    logic [(n-1):0] srca, srcb;
    logic [(n-1):0] aluresult;
    logic [4:0]     writereg;
    logic [(n-1):0] result;

    // "next PC" logic
    flopenr #(n) pcreg(clk, reset, pcen, pcnext, pc);
    mux2 #(n)    adrmux(pc, aluout, iord, adr);

    // IR and MDR
    flopenr #(n) irreg(clk, reset, irwrite, readdata, ir);
    dff #(n)     mdrreg(clk, reset, readdata, mdr);

    assign op = ir[31:26];
    assign funct = ir[5:0];

    // register file logic
    mux2 #(5)   wrmux(ir[20:16], ir[15:11], regdst, writereg);
    mux2 #(n)   resmux(aluout, mdr, memtoreg, result);
    regfile     rf(clk, regwrite, ir[25:21], ir[20:16], writereg, result, rd1, rd2);

    // A and B registers
    dff #(n)    areg(clk, reset, rd1, a);
    dff #(n)    breg(clk, reset, rd2, b);
    assign writedata = b;

    // ALU logic
    signext     se(ir[15:0], signimm);
    sl2         immsh(signimm, signimmsh);

    mux2 #(n)   srcamux(pc, a, alusrca, srca);
    mux4 #(n)   srcbmux(b, 32'd4, signimm, signimmsh, alusrcb, srcb);
    alu         alu(clk, srca, srcb, alucontrol, aluresult, zero);
    dff #(n)    alureg(clk, reset, aluresult, aluout);

    // PCSource logic
    mux3 #(n)   pcmux(aluresult, aluout, {pc[31:28], ir[25:0], 2'b00}, pcsource, pcnext);

endmodule

`endif // DATAPATH
