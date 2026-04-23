//////////////////////////////////////////////////////////////////////////////////
// The Cooper Union
// ECE 251 Spring 2023
// Engineer: Prof Rob Marano
// 
//     Create Date: 2023-02-07
//     Module Name: computer
//     Description: 32-bit Multi-cycle RISC Computer
//
//////////////////////////////////////////////////////////////////////////////////
`ifndef COMPUTER
`define COMPUTER

`timescale 1ns/100ps

`include "cpu.sv"
`include "mem.sv"

module computer
    #(parameter n = 32)(
    input  logic           clk, reset, 
    output logic [(n-1):0] writedata, adr, 
    output logic           memwrite
);
    logic [(n-1):0] readdata;

    // the Multi-cycle RISC CPU
    cpu mips(clk, reset, memwrite, adr, writedata, readdata);
    // the unified memory (instruction + data)
    mem main_mem(clk, memwrite, adr, writedata, readdata);

endmodule

`endif // COMPUTER
