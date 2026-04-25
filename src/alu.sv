// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// ALU module
// =======================================================

`ifndef ALU
`define ALU

`timescale 1ns/100ps

module alu(
    input  logic         clk,
    input  logic [15:0]  a, b,
    input  logic [3:0]   aluCTRL,
    output logic [15:0]  result,
    output logic         zero,
);
    
    assign zero = (result == 16'b0); // zero flag

    // ============ DLD addition trick ===========
    logic [15:0] condinvb; // b or ~b depending on add/sub 
    logic [15:0] sumSlt;   // shared output for adder

    assign condinvb = aluCTRL[2] ? ~b : b;
    assign sumSlt = a + condinvb + aluCTRL[2];

    // ============ MULT ============
    logic [31:0] HiLo; // 16 bits x 16 bits = max 32 bits
    initial begin
        HiLo = 32'b0;
    end

    // ============ ALU operation ============
    always_comb @(a, b, aluCTRL)begin
        case (aluCTRL)
            4'b0000: result = a & b;        // AND
            4'b0001: result = a | b;        // OR
            4'b0010: result = sumSlt;       // ADD
            4'b0011: result = ~(a | b);     // NOR
            4'b0100: result = HiLo[15:0];   // MFLO
            4'b0101: result = HiLo[31:16];  // MFHI
            4'b0110: result = sumSlt;       // SUB
            4'b0111: begin                  // SLT
                  if (a[15] != b[15])
                      if (a[15] > b[15])
                          result = 16'b1;
                      else 
                          result = 16'b0;
                  else
                      if (a < b)
                           result = 16'b1;
                      else 
                          result = 16'b0;
            end
            4'b1000: result = a ^ b;        // XOR
            4'b1001: result = a << b[3:0];  // SLL
            4'b1010: result = a >> b[3:0];  // SRL

            default: result = 16'b0;
        endcase
    end

    always_ff @(negedge clk) begin
        case (aluCTRL)
            4'b1011: HiLo <= a * b;         // MUL
            default: HiLo <= HiLo;
        endcase
    end
endmodule

`endif
