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
`include "mem.sv"

module computer(
    input  logic        clk, reset,

    output logic [15:0] writeData,
    output logic [15:0] dataAddress,
    output logic        memWrite
);

    logic [15:0] pc;
    logic [15:0] aluOut;
    logic [15:0] readData;
    logic [15:0] memAddress;

    cpu cpuUnit(
        .clk(clk),
        .reset(reset),
        .readData(readData),
        .memWrite(memWrite),
        .pc(pc),
        .aluOut(aluOut),
        .writeData(writeData),
        .memAddress(memAddress)
    );

    assign dataAddress = memAddress;

    mem memory(
        .clk(clk),
        .memWrite(memWrite),
        .address(memAddress[6:1]),
        .writeData(writeData),
        .readData(readData)
    );

endmodule

`endif
