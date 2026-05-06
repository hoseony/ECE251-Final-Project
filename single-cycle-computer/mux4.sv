// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// 4:1 mux 
// =======================================================

`ifndef MUX4
`define MUX4

`timescale 1ns/100ps

module mux4 #(parameter n = 16)(
    input   logic [n-1:0] d0,
    input   logic [n-1:0] d1,
    input   logic [n-1:0] d2,
    input   logic [n-1:0] d3,
    input   logic [1:0]  s, //2bit selection pin
    output  logic [n-1:0] data_out
);

    logic [n-1:0] result_01;
    logic [n-1:0] result_23;

    mux2 #(n)u1(.d0(d0), .d1(d1), .s(s[0]), .data_out(result_01));
    mux2 #(n)u2(.d0(d2), .d1(d3), .s(s[0]), .data_out(result_23));

    mux2 #(n)u3(.d0(result_01), .d1(result_23), .s(s[1]), .data_out(data_out));

endmodule

`endif
