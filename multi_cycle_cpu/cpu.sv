//////////////////////////////////////////////////////////////////////////////////
// The Cooper Union
// ECE 251 Spring 2023
// Engineer: Prof Rob Marano
// 
//     Create Date: 2023-02-07
//     Module Name: cpu
//     Description: 32-bit RISC-based CPU (MIPS)
//
// Revision: 1.0
//
//////////////////////////////////////////////////////////////////////////////////
`ifndef CPU
`define CPU

`timescale 1ns/100ps

`include "controller.sv"
`include "datapath.sv"

module cpu
    #(parameter n = 32)(
    input  logic        clk, reset,
    output logic [(n-1):0] adr, writedata,
    input  logic [(n-1):0] readdata,
    output logic        memwrite
);
    logic        pcen, irwrite, regwrite, alusrca, iord, memtoreg, regdst, zero;
    logic [1:0]  alusrcb, pcsource;
    logic [2:0]  alucontrol;
    logic [5:0]  op, funct;

    controller  c(clk, reset, op, funct, zero,
                  pcen, memwrite, irwrite, regwrite,
                  alusrca, iord, memtoreg, regdst,
                  alusrcb, pcsource, alucontrol);

    datapath    dp(clk, reset, adr, writedata, readdata,
                   pcen, irwrite, regwrite, regdst, memtoreg,
                   alusrca, iord, pcsource, alusrcb, alucontrol,
                   zero, op, funct);

endmodule

`endif // CPU