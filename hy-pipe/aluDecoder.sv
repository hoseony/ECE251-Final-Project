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

`include "opcode.sv"

module aluDecoder(
    input logic [3:0] op,
    input logic [1:0] aluOP,
    input logic [3:0] funct,
    output logic [3:0] aluCTRL
);
    always_comb begin
        case (op)
            `OP_ANDI: aluCTRL = `R_AND;
            `OP_ORI:  aluCTRL = `R_OR;
            `OP_XORI: aluCTRL = `R_XOR;
            `OP_SLTI: aluCTRL = `R_SLT;
            `OP_LI:   aluCTRL = `R_PASSB;
            `OP_LUI:  aluCTRL = `R_PASSB;

            default: begin
                case (aluOP)
                    2'b00: aluCTRL = `R_ADD;
                    2'b01: aluCTRL = `R_SUB;
                    2'b10: aluCTRL = funct;
                    2'b11: aluCTRL = `R_PASSB;
                    default: aluCTRL = `R_ADD;
                endcase
            end
        endcase
    end

endmodule

`endif
