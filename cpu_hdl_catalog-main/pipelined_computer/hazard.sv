//////////////////////////////////////////////////////////////////////////////////
// The Cooper Union
// ECE 251 Spring 2026
// Engineer: Prof Rob Marano
// 
//     Create Date: 2026-04-09
//     Module Name: hazard
//     Description: Hazard Unit for 5-stage Pipelined MIPS
//
//////////////////////////////////////////////////////////////////////////////////


module hazard (
    input  logic [4:0] rsD, rtD, rsE, rtE,
    input  logic [4:0] writeregE, writeregM, writeregW,
    input  logic       regwriteE, regwriteM, regwriteW,
    input  logic       memtoregE, memtoregM,
    input  logic       branchD,
    input  logic       intr,
    output logic       forwardaD, forwardbD,
    output logic [1:0] forwardaE, forwardbE,
    output logic       stallF, stallD, flushD, flushE,
    output logic       Exception_Flag
);

    // 1. Forwarding to Execute stage (ALU inputs)
    always_comb begin
        forwardaE = 2'b00;
        forwardbE = 2'b00;

        if (rsE != 0) begin
            if (rsE == writeregM && regwriteM) forwardaE = 2'b10;
            else if (rsE == writeregW && regwriteW) forwardaE = 2'b01;
        end

        if (rtE != 0) begin
            if (rtE == writeregM && regwriteM) forwardbE = 2'b10;
            else if (rtE == writeregW && regwriteW) forwardbE = 2'b01;
        end
    end

    // 2. Forwarding to Decode stage (Branch equality checks)
    assign forwardaD = (rsD != 0) && (rsD == writeregM) && regwriteM;
    assign forwardbD = (rtD != 0) && (rtD == writeregM) && regwriteM;

    // 3. Stalls
    logic lwstall;
    logic branchstall;

    // Load-use data hazard stalling
    assign lwstall = memtoregE && (rtE == rsD || rtE == rtD);

    // Branch hazard stalling (if branch evaluates in ID, must wait for precise conditions)
    assign branchstall = branchD &&
             (regwriteE && (writeregE == rsD || writeregE == rtD) ||
              memtoregM && (writeregM == rsD || writeregM == rtD));

    assign Exception_Flag = intr;

    assign stallD = lwstall || branchstall;
    assign stallF = stallD;       // Stall Fetch if we stall Decode
    assign flushD = Exception_Flag;  // Clear Decode on exception
    assign flushE = stallD || Exception_Flag; // Clear Execute on stall or exception
    
endmodule

