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
    input logic [1:0] aluOP,
    input logic [3:0] funct,

    output logic [3:0] aluCTRL
);

    always_comb begin
        case (aluOP)
            2'b00: aluCTRL = R_ADD;
            2'b01: aluCTRL = R_SUB;
            2'b10: aluCTRL = funct;
            2'b11: aluCTRL = R_PASSB;
            default: aluCTRL = R_ADD;
        endcase
    end

endmodule

`endif
