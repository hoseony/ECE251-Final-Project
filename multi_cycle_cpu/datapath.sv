`ifndef DATAPATH
`define DATAPATH

`timescale 1ns/100ps

`include "regfile.sv"
`include "alu.sv"
`include "dff.sv"
`include "sl2.sv"
`include "mux2.sv"
`include "signext.sv"
`include "flopenr.sv"
`include "mux3.sv"
`include "mux4.sv"

module datapath
    #(parameter n = 32)(
    input  logic        clk, reset,
    // memory interface
    output logic [(n-1):0] adr, writedata,
    input  logic [(n-1):0] readdata,
    // control signals
    input  logic        pcen, irwrite,
    input  logic        regwrite, regdst, memtoreg,
    input  logic        alusrca, iord,
    input  logic [1:0]  pcsource, alusrcb,
    input  logic [2:0]  alucontrol,
    // status signals
    output logic        zero,
    output logic [5:0]  op, funct
);
    logic [(n-1):0] pc, nextpc, md, instr;
    logic [(n-1):0] a, b, srca, srcb;
    logic [(n-1):0] aluresult, aluout;
    logic [(n-1):0] signimm, signimmsh;
    logic [(n-1):0] result, rd1, rd2;
    logic [4:0]     writereg;

    // OP and FUNCT logic extraction
    assign op = instr[31:26];
    assign funct = instr[5:0];

    // PC and Memory Address
    flopenr #(32) pcreg(clk, reset, pcen, nextpc, pc);
    mux2 #(32)    adrmux(pc, aluout, iord, adr);

    // Architectural Registers
    flopenr #(32) ir(clk, reset, irwrite, readdata, instr);
    dff #(32)     mdr(clk, reset, readdata, md);
    dff #(32)     areg(clk, reset, rd1, a);
    dff #(32)     breg(clk, reset, rd2, b);
    dff #(32)     aluoutreg(clk, reset, aluresult, aluout);

    assign writedata = b; // Data sent to memory is B register

    // Register File Logic
    mux2 #(5)     wrmux(instr[20:16], instr[15:11], regdst, writereg);
    mux2 #(32)    resmux(aluout, md, memtoreg, result);
    regfile       rf(clk, regwrite, instr[25:21], instr[20:16], writereg, result, rd1, rd2);
    signext       se(instr[15:0], signimm);
    sl2           immsh(signimm, signimmsh);

    // ALU Logic
    mux2 #(32)    srcamux(pc, a, alusrca, srca);
    mux4 #(32)    srcbmux(b, 32'd4, signimm, signimmsh, alusrcb, srcb);
    alu           alu(clk, srca, srcb, alucontrol, aluresult, zero);

    // Next PC Logic
    mux3 #(32)    pcmux(aluresult, aluout, {pc[31:28], instr[25:0], 2'b00}, pcsource, nextpc);

endmodule

`endif // DATAPATH