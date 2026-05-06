// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// 2:1 mux 
// =======================================================

`ifndef MUX2
`define MUX2

`timescale 1ns/100ps

module mux2 #(parameter n = 16) (
    input   logic [n-1:0] d0,        //input 1 
    input   logic [n-1:0] d1,        //input 2
    input   logic        s,         //selection pin
    output  logic [n-1:0] data_out
);

   assign data_out = s ? d1 : d0;

endmodule

`endif
