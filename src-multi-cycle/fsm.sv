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
    output logic        aluSrcA,     // 0: pc | 1: A register
    output logic        pcWrite,

    output logic [1:0]  regDst,      // 00: Accumulator | 01: rd field (I-type) | 10: R15 $ra
    output logic [1:0]  aluSrcB,     // 00: register B | 01: constant 2
                                     // 10: output of sign extend | 11: signImmSh (sign immediate shift < 1)
    output logic [1:0]  pcSrc,    // 00: output of ALU to pc | 01: aluOutReg | 10: jump
    output logic [1:0]  aluOP,       // 00: add | 01: sub | 10: funct

    output logic        flagWrite,   // 
    output logic        jumpLink,    // pc+2 
    output logic        branchEq,    //
    output logic        branchNe,    //
    output logic        memBase,     // R9 is readReg1
    output logic        branchSrc,   // R0 is readReg1
    output logic        readRd
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
            JALWB     = 4'b1100, // jal (write back)
            LIEXEC    = 4'b1101,
            LIWB      = 4'b1110
    } state_t;

    state_t state, nextState;

    always_ff @(posedge clk or posedge reset)
        if (reset) state <= FETCH;
        else state <= nextState;

    // next state logic
    always_comb begin
        case (state)
            FETCH:      nextState = DECODE;
            DECODE:     case (opcode)
                            OP_RTYPE: nextState = EXECUTER;
                            OP_ADDI:  nextState = ADDIEXEC;
                            OP_LW:    nextState = MEMADR;
                            OP_SW:    nextState = MEMADR;
                            OP_BEQ:   nextState = BRANCH;
                            OP_BNE:   nextState = BRANCH;
                            OP_J:     nextState = JUMP;
                            OP_JAL:   nextState = JUMP;
                            OP_LI:    nextState = LIEXEC;
                            default:  nextState = FETCH;
                        endcase
            MEMADR:     begin 
                if (opcode == OP_LW)
                    nextState = MEMREAD;
                else 
                    nextState = MEMWRITE;
            end
            MEMREAD:    nextState = MEMWB;
            MEMWB:      nextState = FETCH;
            MEMWRITE:   nextState = FETCH;
            EXECUTER:   nextState = ALUWB;
            ALUWB:      nextState = FETCH;
            BRANCH:     nextState = FETCH;
            ADDIEXEC:   nextState = ADDIWB;
            ADDIWB:     nextState = FETCH;
            JUMP:       begin
                if (opcode == OP_JAL)
                    nextState = JALWB;
                else 
                    nextState = FETCH;
            end
            JALWB:      nextState = FETCH;
            LIEXEC: nextState = LIWB;
            LIWB:   nextState = FETCH;
            default:    nextState = FETCH;
        endcase
    end

    // output logic
    always_comb begin
        // default
        irWrite = 1'b0;
        mdrWrite = 1'b0;
        pcWrite = 1'b0;
        pcWriteCond = 1'b0;
        iord = 1'b0;
        memWrite = 1'b0;
        regWrite = 1'b0;
        memToReg = 1'b0;
        aluSrcA = 1'b0;
        flagWrite = 1'b0;
        jumpLink = 1'b0;
        branchEq = 1'b0;
        branchNe = 1'b0;
        memBase = 1'b0;
        branchSrc = 1'b0;
        regDst = 2'b00;
        aluSrcB = 2'b00;
        pcSrc = 2'b00;
        aluOP = 2'b00;
        readRd = 1'b0;

        case (state)
            // send help, this is too much to write comments 
            FETCH: begin
                irWrite = 1;
                pcWrite = 1;
                aluSrcA = 0;
                aluSrcB = 2'b01;
                aluOP   = 2'b00;
                pcSrc   = 2'b00;
            end

            DECODE: begin
                aluSrcA = 0;
                aluSrcB = 2'b11;
                memBase = (opcode == OP_LW  || opcode == OP_SW); 
                branchSrc = (opcode == OP_BEQ || opcode == OP_BNE);
                readRd = (opcode == OP_ADDI);
            end

            MEMADR: begin
                aluSrcA = 1;
                aluSrcB = 2'b10;
                aluOP   = 2'b00;
            end

            MEMREAD: begin
                iord = 1;
                mdrWrite = 1;
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
                aluSrcA = 1;
                aluSrcB = 2'b00;
                aluOP = 2'b10;
                flagWrite = 1;
            end

            ALUWB: begin
                regWrite = 1;
                regDst = 2'b00;
            end

            // Branch compare R0 and rd (idk if I like it)
            BRANCH: begin
                aluSrcA = 1;
                aluSrcB = 2'b00;
                aluOP = 2'b01;
                pcWriteCond = 1;
                pcSrc = 2'b01;
                branchEq = (opcode == OP_BEQ);
                branchNe = (opcode == OP_BNE);
            end

            ADDIEXEC: begin
                aluSrcA = 1;
                aluSrcB = 2'b10;
                aluOP = 2'b00;
            end

            ADDIWB: begin
                regWrite = 1;
                regDst = 2'b01;
            end

            JUMP: begin
                pcWrite = 1;
                pcSrc = 2'b10;
            end

            JALWB: begin
                regWrite = 1;
                regDst = 2'b10;
                jumpLink = 1;
            end

            LIEXEC: begin
                aluSrcA = 1'b0;
                aluSrcB = 2'b10;
                aluOP   = 2'b11;
            end

            LIWB: begin
                regWrite = 1'b1;
                regDst   = 2'b01;
            end

        endcase 
    end
 
endmodule

`endif
