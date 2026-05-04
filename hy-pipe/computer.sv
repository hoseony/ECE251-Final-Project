// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// COMPUTER
// =======================================================

`ifndef COMPUTER
`define COMPUTER

`timescale 1ns/100ps

`include "cpu.sv"
`include "imem.sv"
`include "dmem.sv"

module computer(
    input  logic        clk, reset,
    input  logic        Exception_Flag,

    output logic [15:0] writedata, dataaddr,
    output logic        memwrite
);

    logic [15:0] pcF;       // PC goes to imem
    logic [15:0] instrF;    // instruction comes back from imem
    logic [15:0] aluoutM;   // ALU result = data memory address
    logic [15:0] readdataM; // data read from dmem (LW)

    logic memreadM, dmem_ready, mem_stall;
    assign mem_stall = (memreadM || memwrite) && !dmem_ready;

    cpu cpuUnit(
        .clk(clk), .reset(reset),
        .Exception_Flag(Exception_Flag),
        .mem_stall(mem_stall),
        .pcF(pcF), .instrF(instrF),
        .memwriteM(memwrite), .memreadM(memreadM),
        .aluoutM(aluoutM),
        .writedataM(writedata), .readdataM(readdataM)
    );


    assign dataaddr = aluoutM;

    imem imemUnit(
        .address(pcF[6:1]),
        .readData(instrF)
    );

    dmem dmemUnit(
        .clk(clk),
        .reset(reset),
        .memRead(memreadM),
        .memWrite(memwrite),
        .address(aluoutM),
        .writeData(writedata),
        .dmem_ready(dmem_ready),
        .readData(readdataM)
    );

endmodule

`endif
