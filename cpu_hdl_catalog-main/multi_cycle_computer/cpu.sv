//////////////////////////////////////////////////////////////////////////////////
// The Cooper Union
// ECE 251 Spring 2023
// Engineer: Prof Rob Marano
// 
//     Create Date: 2023-02-07
//     Module Name: cpu
//     Description: 32-bit Multi-cycle MIPS CPU
//
//////////////////////////////////////////////////////////////////////////////////
`ifndef CPU
`define CPU

`timescale 1ns/100ps

`include "controller.sv"
`include "datapath.sv"

module cpu
    #(parameter n = 32)(
    input  logic           clk, reset,
    output logic           memwrite,
    output logic [(n-1):0] adr, writedata,
    input  logic [(n-1):0] readdata
);
    // internal components
    logic       memread, irwrite, regwrite, alusrca, iord, memtoreg, regdst, zero, pcen;
    logic [1:0] alusrcb, pcsource;
    logic [3:0] alucontrol;
    logic [5:0] op, funct;

    controller c(clk, reset, op, funct, zero,
                 memread, memwrite, irwrite, regwrite,
                 alusrca, iord, memtoreg, regdst,
                 alusrcb, pcsource, alucontrol, pcen);

    datapath dp(clk, reset, pcen, irwrite, regwrite,
                alusrca, iord, memtoreg, regdst,
                alusrcb, pcsource, alucontrol,
                zero, op, funct, adr, writedata, readdata);

endmodule

`endif // CPU
