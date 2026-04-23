//////////////////////////////////////////////////////////////////////////////////
// The Cooper Union
// ECE 251 Spring 2023
// Engineer: Prof Rob Marano
// 
//     Create Date: 2023-02-07
//     Module Name: fsm
//     Description: Finite State Machine for Multi-cycle MIPS
//
//////////////////////////////////////////////////////////////////////////////////
`ifndef FSM
`define FSM

`timescale 1ns/100ps

module fsm(
    input  logic       clk, reset,
    input  logic [5:0] op,
    output logic       memread, memwrite, irwrite, regwrite,
    output logic       alusrca, iord, memtoreg, regdst,
    output logic [1:0] alusrcb, pcsource, aluop,
    output logic       pcwrite, pcwritecond
);
    typedef enum logic [3:0] {
        FETCH     = 4'b0000,
        DECODE    = 4'b0001,
        MEMADR    = 4'b0010,
        MEMREAD   = 4'b0011,
        MEMWRITEB = 4'b0100,
        MEMWRITE  = 4'b0101,
        EXECUTER  = 4'b0110,
        ALUWRITEB = 4'b0111,
        BRANCH    = 4'b1000,
        ADDIEXEC  = 4'b1001,
        ADDIWRITEB= 4'b1010,
        JUMP      = 4'b1011
    } state_t;

    state_t state, nextstate;

    // State Register
    always_ff @(posedge clk or posedge reset)
        if (reset) state <= FETCH;
        else       state <= nextstate;

    // Next State Logic
    always_comb begin
        case (state)
            FETCH:      nextstate = DECODE;
            DECODE:     case (op)
                            6'b100011: nextstate = MEMADR; // LW
                            6'b101011: nextstate = MEMADR; // SW
                            6'b000000: nextstate = EXECUTER; // R-type
                            6'b000100: nextstate = BRANCH; // BEQ
                            6'b001000: nextstate = ADDIEXEC; // ADDI
                            6'b000010: nextstate = JUMP; // J
                            default:   nextstate = FETCH;
                        endcase
            MEMADR:     case (op)
                            6'b100011: nextstate = MEMREAD;
                            6'b101011: nextstate = MEMWRITE;
                            default:   nextstate = FETCH;
                        endcase
            MEMREAD:    nextstate = MEMWRITEB;
            MEMWRITEB:  nextstate = FETCH;
            MEMWRITE:   nextstate = FETCH;
            EXECUTER:   nextstate = ALUWRITEB;
            ALUWRITEB:  nextstate = FETCH;
            BRANCH:     nextstate = FETCH;
            ADDIEXEC:   nextstate = ADDIWRITEB;
            ADDIWRITEB: nextstate = FETCH;
            JUMP:       nextstate = FETCH;
            default:    nextstate = FETCH;
        endcase
    end

    // Output Logic
    always_comb begin
        // Defaults
        {pcwrite, pcwritecond, iord, memread, memwrite, irwrite, memtoreg, pcsource, aluop, alusrcb, alusrca, regwrite, regdst} = 15'b0;
        case (state)
            FETCH: begin
                memread = 1;
                irwrite = 1;
                alusrcb = 2'b01; // constant 4
                pcwrite = 1;
            end
            DECODE: begin
                alusrcb = 2'b11; // shift-left-2 immediate
            end
            MEMADR: begin
                alusrca = 1;
                alusrcb = 2'b10; // sign-extended immediate
            end
            MEMREAD: begin
                memread = 1;
                iord = 1;
            end
            MEMWRITEB: begin
                regwrite = 1;
                memtoreg = 1;
            end
            MEMWRITE: begin
                memwrite = 1;
                iord = 1;
            end
            EXECUTER: begin
                alusrca = 1;
                aluop = 2'b10;
            end
            ALUWRITEB: begin
                regwrite = 1;
                regdst = 1;
            end
            BRANCH: begin
                alusrca = 1;
                aluop = 2'b01;
                pcwritecond = 1;
                pcsource = 2'b01;
            end
            ADDIEXEC: begin
                alusrca = 1;
                alusrcb = 2'b10;
            end
            ADDIWRITEB: begin
                regwrite = 1;
            end
            JUMP: begin
                pcwrite = 1;
                pcsource = 2'b10;
            end
        endcase
    end

endmodule

`endif // FSM
