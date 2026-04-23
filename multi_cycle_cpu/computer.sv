//////////////////////////////////////////////////////////////////////////////////
// The Cooper Union
// ECE 251 Spring 2023
// Engineer: Prof Rob Marano
// 
//     Create Date: 2023-02-07
//     Module Name: computer
//     Description: 32-bit RISC
//
// Revision: 1.0
//
//////////////////////////////////////////////////////////////////////////////////
`ifndef COMPUTER
`define COMPUTER

`timescale 1ns/100ps

`include "cpu.sv"
`include "mem.sv"

module computer
    #(parameter n = 32)(
    input  logic        clk, reset,
    output logic [(n-1):0] writedata, dataadr,
    output logic        memwrite
);
    logic [(n-1):0] readdata;

    // mips CPU
    cpu         mips(clk, reset, dataadr, writedata, readdata, memwrite);
    
    // unified memory
    mem         mem(clk, memwrite, dataadr, writedata, readdata);

endmodule

`endif // COMPUTER