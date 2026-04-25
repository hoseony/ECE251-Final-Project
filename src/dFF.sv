// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// D Flip Flop
// =======================================================

`ifndef DFF
`define DFF

`timescale 1ns/100ps

module dff(
    input  logic        clk, r,
    input  logic [15:0] D;
    output logic [15:0] Q;
);

    always_ff @(ck) begin
        if (r) // if reset high, 0
            Q <= 16'b0; 
        else 
            Q <= D;
    end
endmodule

`ifndef
