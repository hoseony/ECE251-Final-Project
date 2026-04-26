// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// Finite State Machine
// =======================================================

`ifndef FSM
`define FSM

`timescale 1ns/100ps

import opcode_pkg::*;

module fsm (
    // ref: Appendix D-29 from textbook
    input  logic        clk, reset,
    input  logic [3:0]  opcode,      // yeah, opcode

    output logic        irWrite,     // IR (Instruction Register)
    output logic        mdrWrite,    // MDR (Memory Data Register)
    output logic        pcWriteCond, // Conditional PC
    output logic        iord,        // choose address 0: pc | 1: alu out register  
    output logic        memWrite,    // 1: write to a memory (sw)
    output logic        regWrite,    // 1: write to register
    output logic        memToReg,    // 1: data from memory | 0: data fromregister
    output logic        aluSrca,     // 0: pc | 1: A register

    output logic [1:0]  regDst,      // 00: Accumulator | 01: rd field (I-type) | 10: R15 $ra
    output logic [1:0]  aluSrcb,     // 00: register B | 01: constant 2
                                     // 10: output of sign extend | 11: signImmSh (sign immediate shift < 1)
    output logic [1:0]  pcSource,    // 00: output of ALU to pc | 01: aluOutReg | 10: jump
    output logic [1:0]  aluOP,       // 00: add | 01: sub | 10: funct

    output logic        flagWrite,   // 
    output logic        jumpLink,    // pc+2 
    output logic        branchEq,    //
    output logic        branchNe,    //
    output logic        memBase,     // R9 is readReg1
    output logic        branchSrc    // R0 is readReg1
);

    typedef enum logic [3:0] {
            FETCH     = 4'b0000, // pc memory -> IR, pc = pc + 2
            DECODE    = 4'b0001, // read regs, compute branch target
            MEMADR    = 4'b0010, // compute address for lw / sw
            MEMREAD   = 4'b0011, // read memory (lw)
            MEMWB     = 4'b0100, // mem -> reg (lw)
            MEMWRITE  = 4'b0101, // write to memory (sw)
            EXECUTER  = 4'b0110, // R-Type execution
            ALUWB     = 4'b0111, // R-Type write back
            BRANCH    = 4'b1000, // beq / bne
            ADDIEXEC  = 4'b1001, // addi execution
            ADDIWB    = 4'b1010, // addi write back
            JUMP      = 4'b1011, // j / jal
            JALWB     = 4'b1100  // jal (write back)
    } state_t;

    state_t state, nextStaet;

    always_ff @(posedge clk or posedge reset)
        if (reset) state <= FETCH;
        else state <= nextState;

    // next state logic
    always_comb begin
        case (state)
            FETCH:      nextState = DECODE;
            DECODE:     case (op)
                            OP_RTYPE: nextState = EXECUTER;
                            OP_ADDI:  nextState = ADDIEXEC;
                            OP_LW:    nextState = MEMADR;
                            OP_SW:    nextState = MEMADR;
                            OP_BEQ:   nextState = BRANCH;
                            OP_BNE:   nextState = BRANCH;
                            OP_J:     nextState = JUMP;
                            OP_JAL:   nextState = JUMP;
                            default:  nextState = FETCH;
                        endcase
            MEMADR:     nextState = (op == OP_LW) ? MEMREAD : MEMWRITE;
            MEMREAD:    nextState = MEMWB;
            MEMWB:      nextState = FETCH;
            MEMWRITE:   nextState = FETCH;
            EXECUTER:   nextState = ALURWBACK;
            ALUWB:      nextState = FETCH;
            BRANCH:     nextState = FETCH;
            ADDIEXEC:   nextState = ADDIWB;
            ADDIWB:     nextState = FETCH;
            JUMP:       nextState = (op == OP_JAL) ? JALWB : FETCH;
            JALWB:      nextState = FETCH;
            default:    nextState = FETCH;
        endcase
    end

    // output logic
    always_comb begin
        // default
        irWrite = mdrWrite = pcWriteCond = iord = memToReg = aluSrca = 0;
        flagWrite = jumpLink = branchEq = branchNe = memBase = branchSrc = 0;
        regDst = aluSrcb = pcSource = aluOP = 2'b00;

        case (state)
            // send help, this is too much to write comments 
            FETCH: begin
                irWrite = 1;
                pcWrite = 1;
                aluSrca = 0;
                aluSrcb = 2'b01;
                aluOP   = 2'b00;
                pcSrc   = 2'b00;
            end

            DECODE: begin
                aluSrca = 0;
                aluSrcb = 2'b11;
                memBase = (op == OP_LW  || op == OP_SW); 
                branchSrc = (op == OP_BEQ || op == OP_BNE);
            end

            MEMADR: begin
                aluSrca = 1;
                aluSrcb = 2'b10;
                aluOP   = 2'b00;
            end

            MEMREAD: begin
                iord = 1;
            end

            MEMWB: begin
                regWrite = 1;
                memToReg = 1;
                regDst = 2'b01;
            end

            MEMWRITE: begin
                memWrite = 1;
                iord = 1;
            end

            EXECUTER: begin
                aluSrca = 1;
                aluSrcb = 2'b00;
                aluOP = 2'b10;
                flagWrite = 1;
            end

            ALUWB: begin
                regWrite = 1;
                regDst = 2'b00;
            end

            // Branch compare R0 and rd (idk if I like it)
            BRANCH: begin
                aluSrca = 1;
                aluSrcb = 2'b00;
                aluOP = 2'b01;
                pcWriteCond = 1;
                pcSrc = 2'b01;
                branchEq = (op == OP_BEQ);
                branchNe = (op == OP_BNE);
            end

            ADDIEXEC: begin
                aluSrca = 0;
                aluSrcb = 2'b10;
                aluOP = 2'b00;
            end

            ADDIWB: begin
                regWrite = 1;
                regDst = 2'b01;
            end

            JUMP: begin
                pcWrite = 1;
                pcSrc = 2'b01;
            end

            JALWB: begin
                regWrite = 1;
                regDst = 2'b10;
                jumpLink = 1;
            end

        endcase 
    end
 
endmodule

`endif
