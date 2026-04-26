// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// Main Decoder
// =======================================================

`ifndef MAINDEC
`define MAINDEC

`timescale 1ns/100ps

import opcode_pkg::*;

module mainDecoder(
    input  logic [3:0] opcode,

    output logic       regWrite,
    output logic       memWrite,
    output logic       memToReg,
    output logic       aluSrc,
    output logic       branchEq,
    output logic       branchNe,
    output logic       jump,
    output logic       jumpLink,
    output logic       memBase,
    output logic       branchSrc,
    output logic [1:0] regDst,
    output logic [1:0] aluOP,
    output logic       flagWrite
);

    logic [14:0] controls;

    assign {
        regWrite, // 1: write to a register
        memWrite, // 1: write to memory (SW)
        memToReg, // 1: data from memory | 0: data from ALU (to the register)
        aluSrc,   // 1: use sign-extended imm | 0: register value
        branchEq, // 1: branch if equal
        branchNe, // 1: branch if not equal
        jump,     // 1: jump
        jumpLink, // 1: jump and Link (save return address $ra)
        regDst,   // 00: Accumulator | 01: rd field (I-type) | 10: R15 $ra
        aluOP,    // 00: add | 01: subtract | 10: function field
        memBase,  // 1: use R9 as ALU input (SW & LW)
        branchSrc,// 1: use R0 as ALU input (BEQ & BNE)
        flagWrite // 1: write to flag
    } = controls;

    always_comb begin
        case (opcode) // decode each opcode to corresponding control signals
            OP_RTYPE: controls = 15'b1_0_0_0_0_0_0_0_00_10_0_0_1;
            OP_ADDI:  controls = 15'b1_0_0_1_0_0_0_0_01_00_0_0_1;
            OP_LW:    controls = 15'b1_0_1_1_0_0_0_0_01_00_1_0_0;
            OP_SW:    controls = 15'b0_1_0_1_0_0_0_0_00_00_1_0_0;
            OP_BEQ:   controls = 15'b0_0_0_0_1_0_0_0_00_01_0_1_0;
            OP_BNE:   controls = 15'b0_0_0_0_0_1_0_0_00_01_0_1_0;
            OP_J:     controls = 15'b0_0_0_0_0_0_1_0_00_00_0_0_0;
            OP_JAL:   controls = 15'b1_0_0_0_0_0_1_1_10_00_0_0_0;

            default:  controls = 15'bxxxxxxxxxxxxxxx; // default case, invalid 
        endcase
    end
endmodule

`endif
