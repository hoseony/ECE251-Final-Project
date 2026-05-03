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
    output logic flushD, flushE
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

    // if EX is a LW and ID needs that register, we can't forward
    // LW after something that use loaded value (load-use)
    logic lwstall;
    assign lwstall = memtoregE && (rtE == rsD || rtE == rtD);

    // branch problems
    // the values branch need might still be in process...
    logic branchstall;
    assign branchstall = (branchD || branchneD) && (
        // EX stage is writing a register that branch needs
        (regwriteE && (writeregE == rsD || writeregE == rtD) ||
        // MEM stage have to load what that branch needs
        (memtoregM && (writeregM == rsD || writeregM == rtD))
    ));

    always_comb begin
        forwardaD = 1'b0;
        forwardbD = 1'b0;

        if (regwriteM && (rsD == writeregM))
            forwardaD = 1'b1;

        if (regwriteM && (rtD == writeregM))
            forwardbD = 1'b1;
    end

    // stall fluch
    // stall IF and ID when load-use or branch hazard
    assign stallF = lwstall || branchstall;
    assign stallD = lwstall || branchstall;

    // EX/MEM/WB doesn't need to stall
    assign stallE = 1'b0;
    assign stallM = 1'b0;
    assign stallW = 1'b0;

    assign flushD = Exception_Flag;

    // flushE : bubble into ID/EX
    assign flushE = lwstall || branchstall || Exception_Flag;

endmodule

`endif
