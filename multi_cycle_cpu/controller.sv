//////////////////////////////////////////////////////////////////////////////////
// The Cooper Union
// ECE 251 Spring 2023
// Engineer: Prof Rob Marano
// 
//     Create Date: 2023-02-07
//     Module Name: controller
//     Description: 32-bit RISC-based CPU controller (MIPS)
//
// Revision: 1.0
//
//////////////////////////////////////////////////////////////////////////////////
`ifndef CONTROLLER
`define CONTROLLER

`timescale 1ns/100ps

`include "maindec.sv"
`include "aludec.sv"

module controller
    #(parameter n = 32)(
    input  logic       clk, reset,
    input  logic [5:0] op, funct,
    input  logic       zero,
    output logic       pcen, memwrite, irwrite, regwrite,
    output logic       alusrca, iord, memtoreg, regdst,
    output logic [1:0] alusrcb, pcsource,
    output logic [2:0] alucontrol
);

    logic [1:0] aluop;
    logic       branch, pcwrite;

    maindec md(clk, reset, op, pcwrite, memwrite, irwrite, regwrite, 
               alusrca, branch, iord, memtoreg, regdst, 
               alusrcb, pcsource, aluop);
    
    aludec  ad(funct, aluop, alucontrol);

    assign pcen = pcwrite | (branch & zero);

endmodule

`endif // CONTROLLER