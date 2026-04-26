// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// OPCODE and FUNCTION FIELD(for R-Type) is declared here.
// =======================================================

package opcode_pkg;
    // OPCODE
    parameter logic [3:0] OP_RTYPE  = 4'b0000; // R-type instructions use function field
    parameter logic [3:0] OP_ADDI   = 4'b0001; // add immediate

    parameter logic [3:0] OP_LW     = 4'b0010; // load word
    parameter logic [3:0] OP_SW     = 4'b0011; // store word
    /* because our ISA does not have enough room for rd and rs,
    *  LW and SW will be look as such:
    *
    *  LW rd, imm8
    *    R[rd] = MEM[R9 + signext(imm8)]
    *
    *  SW rd, imm8
    *    MEM[R9 + signext(imm8)] = R[rd]
    *
    *  --> Deviation from the proposal: I think dropping R10 to GEN or
    *  Reserved would be better
    *
    */

    parameter logic [3:0] OP_BEQ    = 4'b0100; // branch if equal
    parameter logic [3:0] OP_BNE    = 4'b0101; // branch not equal
    parameter logic [3:0] OP_J      = 4'b0110; // jump
    parameter logic [3:0] OP_JAL    = 4'b0111; // jump and link, R15 as $ra

/*  Unused for now
    parameter logic [3:0] OP_       = 4'b1000;
    parameter logic [3:0] OP_       = 4'b1001;
    parameter logic [3:0] OP_       = 4'b1010;
    parameter logic [3:0] OP_       = 4'b1011;
    parameter logic [3:0] OP_       = 4'b1100;
    parameter logic [3:0] OP_       = 4'b1101;
    parameter logic [3:0] OP_       = 4'b1110;
    parameter logic [3:0] OP_       = 4'b1111;
*/

    // FUNCTION FIELD for R-TYPE instructions
    // I made it so that it matches with aluCTRL signal to make my life easier
    parameter logic [3:0] R_AND     = 4'b0000; // AND
    parameter logic [3:0] R_OR      = 4'b0001; // OR
    parameter logic [3:0] R_ADD     = 4'b0010; // ADD
    parameter logic [3:0] R_NOR     = 4'b0011; // NOR
    parameter logic [3:0] R_MFLO    = 4'b0100; // MFLO
    parameter logic [3:0] R_MFHI    = 4'b0101; // MFHI
    parameter logic [3:0] R_SUB     = 4'b0110; // SUB
    parameter logic [3:0] R_SLT     = 4'b0111; // SLT
    parameter logic [3:0] R_XOR     = 4'b1000; // XOR
    parameter logic [3:0] R_SLL     = 4'b1001; // SLL
    parameter logic [3:0] R_SRL     = 4'b1010; // SRL
    parameter logic [3:0] R_MUL     = 4'b1011; // MUL (this saves things to HiLo, you need to load with MFLO or MFHI)

/* Unused for now
    parameter logic [3:0] R_        = 4'b1100;
    parameter logic [3:0] R_        = 4'b1101;
    parameter logic [3:0] R_        = 4'b1110;
    parameter logic [3:0] R_        = 4'b1111;
*/
endpackage
