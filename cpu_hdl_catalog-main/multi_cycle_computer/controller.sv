//////////////////////////////////////////////////////////////////////////////////
// The Cooper Union
// ECE 251 Spring 2023
// Engineer: Prof Rob Marano
// 
//     Create Date: 2023-02-07
//     Module Name: controller
//     Description: 32-bit Multi-cycle MIPS Controller
//
//////////////////////////////////////////////////////////////////////////////////
`ifndef CONTROLLER
`define CONTROLLER

`timescale 1ns/100ps

`include "fsm.sv"
`include "aludec.sv"

module controller
    #(parameter n = 32)(
    input  logic       clk, reset,
    input  logic [5:0] op, funct,
    input  logic       zero,
    output logic       memread, memwrite, irwrite, regwrite,
    output logic       alusrca, iord, memtoreg, regdst,
    output logic [1:0] alusrcb, pcsource,
    output logic [3:0] alucontrol,
    output logic       pcen
);
    logic [1:0] aluop;
    logic       pcwrite, pcwritecond;
    
    fsm fsm(clk, reset, op, memread, memwrite, irwrite, regwrite, 
            alusrca, iord, memtoreg, regdst, alusrcb, pcsource, aluop, 
            pcwrite, pcwritecond);
            
    aludec ad(funct, aluop, alucontrol);

    assign pcen = pcwrite | (pcwritecond & zero);

endmodule

`endif // CONTROLLER
