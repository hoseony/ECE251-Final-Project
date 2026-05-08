// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// hazard
// =======================================================

`ifndef HAZARD
`define HAZARD

`timescale 1ns/100ps

module hazard(
    // register addresses from ID and EX
    // we need to know what they are reading or writing
    input logic [3:0] rsD, rtD,  // source being read in ID 
    input logic [3:0] rsE, rtE,  // soruce being read in EX
    input logic [3:0] writeregE, // destination in EX
    input logic [3:0] writeregW, // destination in MEM
    input logic [3:0] writeregM, // destination in WB

    // write enable signals (you only need to forward if they are writing)
    input logic       regwriteE,  // ex stage 
    input logic       regwriteM, // mem stage
    input logic       regwriteW,  // wb stage

    // memtoReg (maybe data hazard) 
    input logic       memtoregE,
    input logic       memtoregM,

    // branch signal (maybe control hazard)
    input logic       branchD,
    input logic       branchneD,

    // exceptions
    input logic       Exception_Flag,

    // output  signals

    // forwarding to ID
    output logic forwardaD, forwardbD,

    // forwarding to EX (ALU input)
    output logic [1:0] forwardaE, forwardbE,
    
    // stall signals 
    output logic stallF, stallD, stallE, stallM, stallW,

    // flush signals
    output logic flushD, flushE,

    // stalling for dmem
    input logic mem_stall,

    input logic jrD
);

    // forwarding to EX stage
    // regular data hazards can be solved with forwarding

    // forwarding for ALU input A
    always_comb begin
        forwardaE = 2'b00; // default: register file
        if      (rsE == writeregM && regwriteM) forwardaE = 2'b10; // forward from MEM
        else if (rsE == writeregW && regwriteW) forwardaE = 2'b01; // forward from WB
    end

    // forwarding for ALU input B
    always_comb begin
        forwardbE = 2'b00; // default: register file
        if      (rtE == writeregM && regwriteM) forwardbE = 2'b10; // forward from MEM
        else if (rtE == writeregW && regwriteW) forwardbE = 2'b01; // forward from WB
    end

    // stall logic

    // if EX is a LW and ID needs that register, we can't forward yet
    logic lwstall;
    assign lwstall = memtoregE && (
        (writeregE == rsD) ||
        (writeregE == rtD)
    );

    // branch / jr problems
    // BEQ, BNE, and JR are resolved in Decode.
    // If their source register is still being produced, stall.
    logic controlstall;
    assign controlstall = (branchD || branchneD || jrD) && (
        // value is still in EX, cannot forward to Decode yet
        (regwriteE && ((writeregE == rsD) || (writeregE == rtD))) ||

        // value is a load in MEM; wait until loaded value is available
        (memtoregM && ((writeregM == rsD) || (writeregM == rtD)))
    );

    always_comb begin
        forwardaD = 1'b0;
        forwardbD = 1'b0;

        if (regwriteM && (rsD == writeregM))
            forwardaD = 1'b1;

        if (regwriteM && (rtD == writeregM))
            forwardbD = 1'b1;
    end

    // stall IF and ID when load-use or Decode-stage control hazard
    assign stallF = lwstall || controlstall || mem_stall;
    assign stallD = lwstall || controlstall || mem_stall;

    // EX/MEM/WB only freeze for memory stall
    assign stallE = mem_stall;
    assign stallM = mem_stall;
    assign stallW = mem_stall;

    assign flushD = Exception_Flag && !mem_stall;

    // bubble into ID/EX
    assign flushE = (lwstall || controlstall || Exception_Flag) && !mem_stall;

endmodule

`endif
