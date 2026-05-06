// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// Sign Extension
// =======================================================

`ifndef SIGNEXTEND
`define SIGNEXTEND

`timescale 1ns/100ps

module signExtend(
    input logic  [7:0]   A,
    output logic [15:0]  Y
);
    assign Y = { {8{A[7]}}, A };

endmodule

`endif
