//////////////////////////////////////////////////////////////////////////////////
// The Cooper Union
// ECE 251 Spring 2023
// Engineer: Prof Rob Marano
// 
//     Create Date: 2023-02-07
//     Module Name: maindec
//     Description: 32-bit RISC-based CPU main decoder (MIPS)
//
// Revision: 1.0
//
//////////////////////////////////////////////////////////////////////////////////
`ifndef MAINDEC
`define MAINDEC

`timescale 1ns/100ps

module maindec (
    input  logic       clk, reset,
    input  logic [5:0] op,
    output logic       pcwrite, memwrite, irwrite, regwrite,
    output logic       alusrca, branch, iord, memtoreg, regdst,
    output logic [1:0] alusrcb, pcsource, aluop
);

    parameter FETCH   = 4'b0000; // 0
    parameter DECODE  = 4'b0001; // 1
    parameter MEMADR  = 4'b0010; // 2
    parameter MEMRD   = 4'b0011; // 3
    parameter MEMWB   = 4'b0100; // 4
    parameter MEMWR   = 4'b0101; // 5
    parameter RTYPEEX = 4'b0110; // 6
    parameter RTYPEWB = 4'b0111; // 7
    parameter BEQEX   = 4'b1000; // 8
    parameter ADDIEX  = 4'b1001; // 9
    parameter ADDIWB  = 4'b1010; // 10
    parameter JEX     = 4'b1011; // 11

    logic [3:0] state, nextstate;
    logic [14:0] controls;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) state <= FETCH;
        else       state <= nextstate;
    end

    always_comb begin
        case (state)
            FETCH:   nextstate = DECODE;
            DECODE:  case(op)
                         6'b100011: nextstate = MEMADR; // LW
                         6'b101011: nextstate = MEMADR; // SW
                         6'b000000: nextstate = RTYPEEX; // R-TYPE
                         6'b000100: nextstate = BEQEX;   // BEQ
                         6'b001000: nextstate = ADDIEX;  // ADDI
                         6'b000010: nextstate = JEX;     // J
                         default:   nextstate = 4'bxxxx; // should never happen
                     endcase
            MEMADR:  case(op)
                         6'b100011: nextstate = MEMRD;
                         6'b101011: nextstate = MEMWR;
                         default:   nextstate = FETCH;
                     endcase
            MEMRD:   nextstate = MEMWB;
            MEMWB:   nextstate = FETCH;
            MEMWR:   nextstate = FETCH;
            RTYPEEX: nextstate = RTYPEWB;
            RTYPEWB: nextstate = FETCH;
            BEQEX:   nextstate = FETCH;
            ADDIEX:  nextstate = ADDIWB;
            ADDIWB:  nextstate = FETCH;
            JEX:     nextstate = FETCH;
            default: nextstate = FETCH;
        endcase
    end

    assign {pcwrite, memwrite, irwrite, regwrite, alusrca, branch,
            iord, memtoreg, regdst, alusrcb, pcsource, aluop} = controls;

    always_comb begin
        case (state)
            FETCH:   controls = 15'b1_0_1_0_0_0_0_0_0_01_00_00;
            DECODE:  controls = 15'b0_0_0_0_0_0_0_0_0_11_00_00;
            MEMADR:  controls = 15'b0_0_0_0_1_0_0_0_0_10_00_00;
            MEMRD:   controls = 15'b0_0_0_0_0_0_1_0_0_00_00_00;
            MEMWB:   controls = 15'b0_0_0_1_0_0_0_1_0_00_00_00;
            MEMWR:   controls = 15'b0_1_0_0_0_0_1_0_0_00_00_00;
            RTYPEEX: controls = 15'b0_0_0_0_1_0_0_0_0_00_00_10;
            RTYPEWB: controls = 15'b0_0_0_1_0_0_0_0_1_00_00_00;
            BEQEX:   controls = 15'b0_0_0_0_1_1_0_0_0_00_01_01;
            ADDIEX:  controls = 15'b0_0_0_0_1_0_0_0_0_10_00_00;
            ADDIWB:  controls = 15'b0_0_0_1_0_0_0_0_0_00_00_00;
            JEX:     controls = 15'b1_0_0_0_0_0_0_0_0_00_10_00;
            default: controls = 15'b0_0_0_0_0_0_0_0_0_00_00_00;
        endcase
    end

endmodule

`endif // MAINDEC