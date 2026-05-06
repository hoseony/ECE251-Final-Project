// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// instruction memory
// =======================================================

`ifndef IMEM
`define IMEM

`timescale 1ns/100ps

module imem(
    input logic [5:0] address,      // instruction address, 6bits (2^6 for now)
    output logic [15:0] readData    // 16-bit instruction
);

    logic [15:0] RAM [0:63]; //2^6 = 64, 64-1

    integer i;

    initial begin
        for (i = 0; i < 64; i = i + 1)
            RAM[i] = 16'hF000;   // NOP

        $readmemh("../programs/program", RAM);
    end

    assign readData = RAM[address]; // word aligned

endmodule

`endif
