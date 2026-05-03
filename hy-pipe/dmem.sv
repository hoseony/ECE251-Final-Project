// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// data memory
// =======================================================

`ifndef DMEM
`define DMEM

`timescale 1ns/100ps

module dmem(
    input logic         clk, memWrite, // write Enable
    input logic [15:0]  address,
    // address to store (in dmem) 
    // * this does not really need to match with imem size but for simplicity
    input logic [15:0]  writeData,    // Data to store

    output logic [15:0] readData      // loading data from memory
);

    logic [15:0] RAM [0:63]; //2^6 = 64, 64-1

    integer i;
    initial begin
        for (i = 0; i < 64; i = i + 1)
            RAM[i] = 16'b0;
    end
    
    assign readData = RAM[address[6:1]];

    always_ff @(posedge clk) begin
        if (memWrite)
            RAM[address[6:1]] <= writeData;
    end
endmodule

`endif
