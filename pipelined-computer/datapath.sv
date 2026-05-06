// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// Datapath
// =======================================================

`ifndef DATAPATH
`define DATAPATH


`include "alu.sv"
`include "registerFile.sv"
`include "mux2.sv"
`include "mux4.sv"
`include "signExtend.sv"
`include "sl1.sv"
`include "opcode.sv"

`timescale 1ns/100ps

module datapath(
    input  logic        clk, reset,

    // IF (F stage)
    output logic [15:0] pcF,        // next PC
    input  logic [15:0] instrF,     // next instruction

    // MEM (M stage)
    output logic [15:0] aluoutM, writedataM,
    input  logic [15:0] readdataM,
    output logic        memwriteM_out,

    // Control signals (D stage)
    input  logic        regwriteD, memwriteD, memtoregD,
    input  logic        alusrcD,
    input  logic [1:0]  regdstD,
    input  logic        branchD, branchneD,
    input  logic        jumpD, jumplinkD,
    input  logic        membaseD, branchsrcD,
    input  logic        flagwriteD,
    input  logic [3:0]  alucontrolD,

    // Instruction to controller
    output logic [15:0] instrD,

    // Hazard unit inputs
    input  logic        stallF, stallD, stallE, stallM, stallW,
    input  logic        flushD, flushE,
    input  logic        forwardaD, forwardbD,
    input  logic [1:0]  forwardaE, forwardbE,

    // Hazard unit outputs
    output logic [3:0]  rsD, rtD, rsE, rtE,
    output logic [3:0]  writeregE, writeregM, writeregW,
    output logic        regwriteE, regwriteM, regwriteW,
    output logic        memtoregE, memtoregM,

    // Exception handling
    input  logic        Exception_Flag
);

    // IF (instruction fetch):  send PC to imem, get instruction, compute pc+2, decide what pcNext is
    // ID (instruction decode): decode instruction field (opcode, rs, rt, rd, imm)
    //                          read register file (get values), sign extend,
    //                          compute branch target, resolve branch, epc
    // EX (execute):            ALU computing, forwarding if needed, select
    //                          destination, compute flags

    // ============== FETCH STAGE ==============
    
    logic [15:0] pcNextFD, pcPlus2F, pcNextBrFD, pcJumpFD;
    logic pcSrcD, pcSrcNeD; //for BEQ and BNE
    logic jrD;
    
    logic [15:0] pcPlus2D;

    assign pcPlus2F = pcF + 16'd2;  // next PC (default)
    assign jrD = (instrD[15:12] == `OP_JR);
    
    // This determines what will be our next PC
    always_comb begin
        if (Exception_Flag)          pcNextFD = 16'hFF00; // for now, let's move it here
        else if (jumpD)              pcNextFD = pcJumpFD;
        else if (jrD)                pcNextFD = comparaD;
        else if (pcSrcD || pcSrcNeD) pcNextFD = pcNextBrFD;
        else                         pcNextFD = pcPlus2F;
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset)        pcF <= 16'b0;
        else if (~stallF) pcF <= pcNextFD;
    end

    // ========= IF /  ID register ========
    // here, we latches instruction and pc+2 into D stage
    // flush: bubble | stall: freeze

    always_ff @(posedge clk or posedge reset) begin 
        if (reset || flushD) begin
            // flushD comes from hazard unit for exceptions
            instrD      <= 16'hF000;
            pcPlus2D    <= 16'b0;
        end else if(~stallD) begin
            // if branch or jump, insert we need to zero the instrD because
            // the next instruction that got fetched is wrong
            // Though, we still need pcPlus2D because of the jump logic
            instrD      <= (pcSrcD || pcSrcNeD || jumpD || jrD) ? 16'hF000 : instrF;
            pcPlus2D    <= pcPlus2F;
        end
    end

    // ============== Decode Stage ==============

    logic [3:0]  readReg1D, readReg2D, rdD;
    logic [15:0] srcaD, srcbD;
    logic [15:0] signImmD, signImmShD;
    logic [15:0] resultW;
    logic        flagwriteW;
    logic [15:0] flagsdataW;

    // readReg1 select (what to put into ALU input A)
    logic [3:0] instrD_rs, instrD_rd;
    assign instrD_rs = instrD[7:4];
    assign instrD_rd = instrD[11:8];

    always_comb begin
        if (membaseD)        readReg1D = 4'd9;         // LW/SW R9 is the base pointer
        else if (branchsrcD) readReg1D = 4'd0;         // BEQ/BNE compare against R0
        else if (jrD)        readReg1D = instrD_rd;
        else if (alusrcD)    readReg1D = instrD_rd; // ADDI/LI rd is part of the source
        else                 readReg1D = instrD_rs;  // R-type rs field
    end

    // readReg2 (always rd/rt field)
    assign readReg2D = instrD[11:8]; // this is rd/rt always (except I)
    assign rdD       = instrD[11:8]; // destination for I-type
    assign rsD       = readReg1D;    // to hazard unit, what reg1
    assign rtD       = readReg2D;    // to hazard unit, what reg2

    // let's read it from the registers
    registerFile rf(.clk(clk), .writeEnable(regwriteW),
        .readReg1(readReg1D), .readReg2(readReg2D),
        .writeReg(writeregW), .writeData(resultW),
        .readData1(srcaD), .readData2(srcbD),
        .flagWrite(flagwriteW), .flagsData(flagsdataW));

    
    signExtend se(.A(instrD[7:0]), .Y(signImmD));
    sl1        immsh(.A(signImmD), .Y(signImmShD));
    
    logic [15:0] aluImmD;
    assign aluImmD = (instrD[15:12] == `OP_LUI) ? {instrD[7:0], 8'b0} : signImmD;

    assign pcJumpFD = {pcPlus2D[15:13], instrD[11:0], 1'b0};
    assign pcNextBrFD = pcPlus2D + signImmShD;

    // ============ branch forwarding ==========
    // since the value we still need might be in MEM stage,
    // we should forward from MEM if needed
    // if forwardaD is 1, forward from MEM stage
    logic [15:0] comparaD, comparbD; // values being compared 

    // values from register file, values forwarded from MEM stage , forwardaD, comparaD
    mux2 #(16) fwdadmux(.d0(srcaD), .d1(aluoutM), .s(forwardaD), .data_out(comparaD));
    mux2 #(16) fwdbdmux(.d0(srcbD), .d1(aluoutM), .s(forwardbD), .data_out(comparbD));

    // making signals for branches
    assign pcSrcD = branchD & (comparaD == comparbD); //BEQ
    assign pcSrcNeD = branchneD & (comparaD != comparbD); //BNE

    // EPC
    // save the PC if exception
    logic [15:0] epc;
    always_ff @(posedge clk or posedge reset) begin
        if (reset)                  epc <= 16'b0; // reset
        else if (Exception_Flag)    epc <= pcPlus2D - 16'd2; // store faulting instructions
    end
    
    // ======= ID / EX register =======
    //           D --> E
    logic [15:0] srcaE, srcbE, signImmE, pcPlus2E;
    logic [3:0] rdE;
    logic       memwriteE, alusrcE;
    logic [1:0] regdstE;
    logic       flagwriteE, jumplinkE;
    logic [3:0] alucontrolE;

    always_ff @(posedge clk or posedge reset) begin
        if (reset || flushE) begin
            srcaE       <= 16'b0;
            srcbE       <= 16'b0;
            signImmE    <= 16'b0;
            pcPlus2E    <= 16'b0;

            rsE         <= 4'b0;
            rtE         <= 4'b0;
            rdE         <= 4'b0;

            regwriteE   <= 1'b0;
            memwriteE   <= 1'b0;
            memtoregE   <= 1'b0;
            alusrcE     <= 1'b0;
            regdstE     <= 2'b0;
            flagwriteE  <= 1'b0;
            jumplinkE   <= 1'b0;
            alucontrolE <= 4'b0;
        end else if (~stallE) begin
            srcaE       <= srcaD;
            srcbE       <= srcbD;
            signImmE    <= aluImmD;
            pcPlus2E    <= pcPlus2D;

            rsE         <= rsD;
            rtE         <= rtD;
            rdE         <= rdD;

            regwriteE   <= regwriteD;
            memwriteE   <= memwriteD;
            memtoregE   <= memtoregD;
            alusrcE     <= alusrcD;
            regdstE     <= regdstD;
            flagwriteE  <= flagwriteD;
            jumplinkE   <= jumplinkD;
            alucontrolE <= alucontrolD;
        end
    end
    // ======= Execute ======
    logic [15:0] srcA2E, srcB2E, srcB3E, aluoutE;
    //           ALU input after forwarding mux, 
    //           ALU input B after forwarding mux,
    //           Result out from ALU 
    logic        zeroE, negativeE, carryE, overflowE;
    logic [15:0] flagsdataE;

    // forwarding for ALU input A
    mux4 #(16) fwdaEmux(
        .d0(srcaE),     // from register file
        .d1(resultW),   // from WB
        .d2(aluoutM),   // from MEM
        .d3(16'b0),     //unused
        .s(forwardaE),
        .data_out(srcA2E)
    );

    // forwarding for ALU input B
    mux4 #(16) fwdbEmux(
        .d0(srcbE),
        .d1(resultW),
        .d2(aluoutM),
        .d3(16'b0),
        .s(forwardbE),
        .data_out(srcB2E)
    );

    mux2 #(16) srcBmux(.d0(srcB2E), .d1(signImmE), .s(alusrcE), .data_out(srcB3E));

    alu aluUnit(
        .clk(clk), .a(srcA2E), .b(srcB3E), 
        .aluCTRL(alucontrolE), .result(aluoutE),
        .zero(zeroE), .negative(negativeE),
        .carry(carryE), .overflow(overflowE)
    );

    // put flags into right format
    assign flagsdataE = {12'b0, overflowE, carryE, negativeE, zeroE};

    // selecting destination register
    always_comb begin
        case (regdstE)
            2'b00: writeregE = 4'd0;  // accumulator
            2'b01: writeregE = rdE;   // rd field
            2'b10: writeregE = 4'd15; // R15 = return address
            default: writeregE = 4'd0;
        endcase
    end

    // ======= EX / MEM register =======
    //           E --> M
    logic        flagwriteM, jumplinkM;
    logic [15:0] flagsdataM, pcPlus2M;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            aluoutM       <= 16'b0;
            writedataM    <= 16'b0;
            writeregM     <= 4'b0;

            regwriteM     <= 1'b0;
            memtoregM     <= 1'b0;
            memwriteM_out <= 1'b0;

            flagwriteM    <= 1'b0;
            flagsdataM    <= 16'b0;
            jumplinkM     <= 1'b0;
            pcPlus2M      <= 16'b0;
        end else if (~stallM) begin
            aluoutM       <= aluoutE;
            writedataM    <= srcB2E;   
            writeregM     <= writeregE;

            regwriteM     <= regwriteE;
            memtoregM     <= memtoregE;
            memwriteM_out <= memwriteE;

            flagwriteM    <= flagwriteE;
            flagsdataM    <= flagsdataE;
            jumplinkM     <= jumplinkE;
            pcPlus2M      <= pcPlus2E;
        end
    end

    // ===== MEM / WB ===== 
    //        M -> W

    logic        memtoregW, jumplinkW;
    logic [15:0] readdataW, aluoutW, pcPlus2W;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            readdataW <= 16'b0;
            aluoutW <= 16'b0;
            pcPlus2W <= 16'b0;
            writeregW <= 4'b0;

            regwriteW <= 1'b0;
            memtoregW <= 1'b0;
            flagwriteW <= 1'b0;
            flagsdataW <= 16'b0;
            jumplinkW <=1'b0;
        end else if (~stallW) begin
            readdataW <= readdataM;
            aluoutW <= aluoutM;
            pcPlus2W <= pcPlus2M;
            writeregW <= writeregM;

            regwriteW <= regwriteM;
            memtoregW <= memtoregM;
            flagwriteW <= flagwriteM;
            flagsdataW <= flagsdataM;
            jumplinkW <= jumplinkM;
        end
    end

    // ==== WB ====
    logic [15:0] aluOrMemW;

    // memtoreg: 0 = alu result, 1 = data from memory (lw)
    mux2 #(16) resMux(
        .d0(aluoutW),
        .d1(readdataW),
        .s(memtoregW),
        .data_out(aluOrMemW)
    );

    // jumplink 0 = normal, 1 = pc+2 return address
    mux2 #(16) jalMux(
        .d0(aluOrMemW),
        .d1(pcPlus2W),
        .s(jumplinkW),
        .data_out(resultW) // goes back to regfile port
    );


endmodule

`endif
