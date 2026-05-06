// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// ADDER
// =======================================================
`ifndef ADDER
`define ADDER

`timescale 1ns/100ps

module adder(
    input  logic [15:0] A,
    input  logic [15:0] B,
    output logic [15:0] Y
);

    assign Y = A + B;
endmodule

`endif
