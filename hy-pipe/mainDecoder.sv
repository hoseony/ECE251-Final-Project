// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// main decoder
// =======================================================

`ifndef MAINDEC
`define MAINDEC

`timescale 1ns/100ps

module maindec(
    input  logic [3:0] op,

    output logic       regWrite,
    output logic       memWrite,
    output logic       memToReg,
    output logic       aluSrc,
    output logic [1:0] regDst,
    output logic [1:0] aluOP,
    output logic       branch,
    output logic       branchNe,
    output logic       jump,
    output logic       jumpLink,
    output logic       memBase,
    output logic       branchSrc,
    output logic       flagWrite
);

    import opcode_pkg::*;

    logic [14:0] controls;

    assign {regWrite, memWrite, memToReg, aluSrc,
            regDst, aluOP,
            branch, branchNe, jump, jumpLink,
            memBase, branchSrc, flagWrite} = controls; 

    always_comb begin
        case (op)
            //                     rW mW mR aS  rD  aO  br bN  j jL mB bS fW
            OP_RTYPE: controls = 15'b1_0_0_0_00_10_0_0_0_0_0_0_1;
            OP_ADDI:  controls = 15'b1_0_0_1_01_00_0_0_0_0_0_0_0;
            OP_LW:    controls = 15'b1_0_1_1_01_00_0_0_0_0_1_0_0;
            OP_SW:    controls = 15'b0_1_0_1_00_00_0_0_0_0_1_0_0;
            OP_BEQ:   controls = 15'b0_0_0_0_00_01_1_0_0_0_0_1_0;
            OP_BNE:   controls = 15'b0_0_0_0_00_01_0_1_0_0_0_1_0;
            OP_J:     controls = 15'b0_0_0_0_00_00_0_0_1_0_0_0_0;
            OP_JAL:   controls = 15'b1_0_0_0_10_00_0_0_1_1_0_0_0;
            OP_LI:    controls = 15'b1_0_0_1_01_11_0_0_0_0_0_0_0;
            default:  controls = 15'b0_0_0_0_00_00_0_0_0_0_0_0_0;
        endcase
    end
endmodule
`endif
