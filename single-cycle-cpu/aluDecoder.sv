// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// ALU decoder
// =======================================================

`ifndef ALUDEC
`define ALUDEC

`timescale 1ns/100ps

import opcode_pkg::*;

module aluDecoder(
    input logic [1:0] aluOP, // 00: add | 01: subtract | 10: function field
    input logic [3:0] funct,

    output logic [3:0] aluCTRL
);

    always_comb begin
        case (aluOP)
            2'b00: aluCTRL = R_ADD; // 00: add
            2'b01: aluCTRL = R_SUB; // 01: subtract
            2'b10: aluCTRL = funct; // 10: function field
            
            default: aluCTRL = R_ADD;
        endcase
    end
endmodule

`endif
