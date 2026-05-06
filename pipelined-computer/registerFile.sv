// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// register file 
// =======================================================

`ifndef REGFILE
`define REGFILE

`timescale 1ns/100ps

module registerFile(
    input logic        clk,
    input logic        writeEnable, // enable writing

    input logic [3:0]  readReg1,    // Firt reg to read
    input logic [3:0]  readReg2,    // Second reg to read
    input logic [3:0]  writeReg,    // Destination
    input logic [15:0] writeData,   // Data that's going to be stored in Destination

    output logic [15:0] readData1,  // output of readReg1
    output logic [15:0] readData2,  // output of readReg2

    input logic         flagWrite,
    input logic  [15:0] flagsData
);

    // creating registerFile
    // 16 of 16 bit register
    logic [15:0] registers [0:15];

    integer i;

    initial begin
        for (i = 0; i < 16; i = i + 1)
            registers[i] = 16'b0;
    end

    // Unlike MIPS, our Register 0 is Accumulator, so we should be able to write on that register
    always_ff @(negedge clk) begin
        if (writeEnable)
            registers[writeReg] <= writeData;
        if (flagWrite)
            registers[12] <= flagsData;
    end

    assign readData1 = registers[readReg1];
    assign readData2 = registers[readReg2];

endmodule

`endif
