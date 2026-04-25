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

    output logic [15:0] writeData,
    output logic [15:0] dataAddress,
    output logic        memWrite
);

    logic [15:0] pc;
    logic [15:0] instr;
    logic [15:0] readData;

    cpu cpuUnit(
        .clk(clk),
        .reset(reset),
        .instr(instr),
        .readData(readData),
        .pc(pc),
        .aluOut(dataAddress),
        .writeData(writeData),
        .memWrite(memWrite)
    );

    imem instrMem(
        .address(pc[6:1]),
        .readData(instr)
    );

    dmem dataMem(
        .clk(clk),
        .memWrite(memWrite),
        .address(dataAddress[5:0]),
        .writeData(writeData),
        .readData(readData)
    );
endmodule

`endif
