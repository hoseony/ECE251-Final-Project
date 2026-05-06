// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// SL1
// =======================================================

`ifndef SL1
`define SL1

`timescale 1ns/100ps

module sl1(
    input  logic [15:0] A,
    output logic [15:0] Y
);
    assign Y = {A[14:0], 1'b0};
endmodule

`endif
