// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// ALU module
// =======================================================

// * apparently it throws an error when I do any bitselections in always_comb, so it ended up becoming bit massy

`ifndef ALU
`define ALU

`timescale 1ns/100ps

module alu(
    input  logic         clk,
    input  logic [15:0]  a, b,
    input  logic [3:0]   aluCTRL,
    output logic [15:0]  result,
    output logic         zero,
    output logic         negative,
    output logic         carry,
    output logic         overflow
);
    
    // ============ DLD addition trick ===========
    logic [15:0] condinvb;      // b or ~b depending on add/sub 
    logic [15:0] sumSlt;
    logic [16:0] fullSum;

    assign condinvb = aluCTRL[2] ? ~b : b;
    assign fullSum = {1'b0, a} + {1'b0, condinvb} + {16'b0, aluCTRL[2]};
    assign sumSlt = fullSum[15:0];
    
    // ============ FLAGS ============
    assign zero = (result == 16'b0); // zero flag
    assign negative = result[15];    // negative flag
    assign carry = (aluCTRL == 4'b0010 || aluCTRL == 4'b0110) ? fullSum[16] : 1'b0;      // carry flag

    logic aSign, bSign, sumSign, bSg;
    assign aSign = a[15];
    assign bSign = condinvb[15];
    assign sumSign = sumSlt[15];
    assign bSg = b[15];


    always_comb begin
        if (aluCTRL == 4'b0010 || aluCTRL == 4'b0110) begin
           // if both input same sign but result sign diff
           if (aSign == bSign && sumSign != aSign)
                overflow = 1'b1;
           else 
                overflow = 1'b0;
        end else begin
            overflow = 1'b0;
        end
    end

    // ============ ALU operation ============

    // For multiplication:
    logic [31:0] HiLo;              // 16 bits x 16 bits = max 32 bits
    logic [15:0] HiLo_lo;           // lower 16 bits
    logic [15:0] HiLo_hi;           // upper 16 bits

    assign HiLo_lo = HiLo[15:0];    
    assign HiLo_hi = HiLo[31:16];

    // for SLL and SRL
    logic [3:0] bShiftAmt;
    assign bShiftAmt = b[3:0];

    always_comb begin
        case (aluCTRL)
            4'b0000: result = a & b;        // AND
            4'b0001: result = a | b;        // OR
            4'b0010: result = sumSlt;       // ADD
            4'b0011: result = ~(a | b);     // NOR
            4'b0100: result = HiLo_lo;      // MFLO
            4'b0101: result = HiLo_hi;      // MFHI
            4'b0110: result = sumSlt;       // SUB
            4'b0111: begin                  // SLT
                  if (aSign != bSg)
                      if (aSign > bSg)
                          result = 16'b1;
                      else 
                          result = 16'b0;
                  else
                      if (a < b)
                           result = 16'b1;
                      else 
                          result = 16'b0;
            end
            4'b1000: result = a ^ b;           // XOR
            4'b1001: result = a << bShiftAmt;  // SLL
            4'b1010: result = a >> bShiftAmt;  // SRL
            4'b1100: result = b;

            default: result = 16'b0;
        endcase
    end

    // ============ signed multiplication ============
    logic signed [15:0] aSigned;
    logic signed [15:0] bSigned;
    logic signed [31:0] HiLoSigned;

    assign HiLoSigned = aSigned * bSigned;

    assign aSigned = a;
    assign bSigned = b;

    always_ff @(negedge clk) begin
        case (aluCTRL)
            4'b1011: HiLo <= HiLoSigned;         // MUL
            default: HiLo <= HiLo;
        endcase
    end
endmodule

`endif
