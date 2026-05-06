// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// Memory (imem + dmem)
// =======================================================

`ifndef MEM
`define MEM

`timescale 1ns/100ps

module mem (
    input  logic         clk,
    input  logic         memWrite,
    input  logic [5:0]   address,
    input  logic [15:0]  writeData,

    output logic [15:0]  readData
);

    logic [15:0] RAM [0:63];

    initial begin
        integer i;
        for (i = 0; i < 64; i = i +1)
           RAM[i] = 16'b0; 
        $readmemh("../programs/program", RAM);
    end
        
    assign readData = RAM[address];

    always_ff @(posedge clk) begin
        if (memWrite)
            RAM[address] <= writeData;
    end

endmodule

`endif
