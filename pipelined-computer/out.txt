// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// ADDER
// =======================================================

`ifndef ADDER
`define ADDER

`timescale 1ns/100ps

module adder(
    input  logic [15:0] A,
    input  logic [15:0] B,
    output logic [15:0] Y
);

    assign Y = A + B;
endmodule

`endif
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
            4'b1101: result = a;
            4'b1110: result = ~a;
            4'b1111: result = (~a) + 16'd1;

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
// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// ALU decoder
// =======================================================

`ifndef ALUDEC
`define ALUDEC

`timescale 1ns/100ps

`include "opcode.sv"

module aluDecoder(
    input logic [3:0] op,
    input logic [1:0] aluOP,
    input logic [3:0] funct,
    output logic [3:0] aluCTRL
);
    always_comb begin
        case (op)
            `OP_ANDI: aluCTRL = `R_AND;
            `OP_ORI:  aluCTRL = `R_OR;
            `OP_XORI: aluCTRL = `R_XOR;
            `OP_SLTI: aluCTRL = `R_SLT;
            `OP_LI:   aluCTRL = `R_PASSB;
            `OP_LUI:  aluCTRL = `R_PASSB;

            default: begin
                case (aluOP)
                    2'b00: aluCTRL = `R_ADD;
                    2'b01: aluCTRL = `R_SUB;
                    2'b10: aluCTRL = funct;
                    2'b11: aluCTRL = `R_PASSB;
                    default: aluCTRL = `R_ADD;
                endcase
            end
        endcase
    end

endmodule

`endif
// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// direct mapped cache
// =======================================================

`ifndef CACHEDIRECT
`define CACHEDIRECT

`timescale 1ns/100ps

module cache_directMapped(
    input  logic        clk, reset,

    input  logic [15:0] addr,        // from aluoutM
    input  logic [15:0] writedata,   // from writedataM
    input  logic        memwrite,    // SW
    input  logic        memread,     // LW (memtoregM)
    output logic [15:0] readdata,    // to readdataM
    output logic        stall,       // to hazard unit

    output logic [15:0] mem_addr,
    output logic [15:0] mem_writedata,
    output logic        mem_write,
    output logic        mem_read,
    input  logic [15:0] mem_readdata,
    input  logic        mem_ready
);

// ------- Cache structure ------- 
// 8 blocks, each contains 1 valid, 12 tag bits, 16 data bits
logic        validArray [0:7];
logic [11:0] tagArray   [0:7];
logic [15:0] dataArray  [0:7];

// ------- Parsing Address ------- 
// [15:4]: tag, [3:1]: index, offset ignored
logic [11:0] tag;
logic [2:0] index;

assign tag = addr[15:4];
assign index = addr [3:1];

// ------- Hit / Miss Logic -------
logic hit, miss;

assign hit = validArray[index] && (tagArray[index] == tag);
assign miss = (memread || memwrite) && !hit;
assign readdata = hit ? dataArray[index] : 16'bx;

// ------- Main Memory & FSM logic -------
typedef enum logic { IDLE, FETCHING } state_t;
state_t state, nextState;

// IDLE: normal operation
always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= IDLE;
        for (int i = 0; i < 8; i++) begin
            validArray[i] <= 16'b0;
            tagArray[i] <= 16'b0;
            dataArray <= 16'b0;
        end
    end else begin
        state <= nextState;

        // if Hit and memory write, update the cache
        if (memwrite && hit) begin
            dataArray[index] <= writedata;
        end

        // if it missed, you should put the data in to the cache
        // in fetch it returns data, so we can now fill that in
        if (state == FETCHING && mem_ready) begin
            validArray[index] <= 1'b1;
            tagArray[index] <= tag;
            dataArray[index] <= memwrite ? writedata : mem_readdata;
        end
    end
end

always_comb begin
    nextState = state;
    stall    = 0;
    mem_addr = addr;
    mem_writedata = writedata;
    mem_write = 0;
    mem_read = 0;

    case (state)
        IDLE: begin
            if (memread && !hit) begin
                // read miss — go fetch from memory
                stall      = 1'b1;
                mem_read   = 1'b1;
                next_state = FETCH;
            end else if (memwrite && hit) begin
                // write hit — write through to memory
                mem_write  = 1'b1;
            end else if (memwrite && !hit) begin
                // write miss — write to memory only (no-allocate)
                mem_write  = 1'b1;
            end
        end

        FETCH: begin
            // stall CPU until memory responds
            stall      = 1'b1;
            mem_read   = 1'b1;
            nextstate = IDLE; // dmem responds in 1 cycle
            end
    endcase
end

endmodule

`endif
// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// COMPUTER
// =======================================================

`ifndef COMPUTER
`define COMPUTER

`timescale 1ns/100ps

`include "cpu.sv"
`include "imem.sv"
`include "dmem.sv"

module computer(
    input  logic        clk, reset,
    input  logic        Exception_Flag,

    output logic [15:0] writedata, dataaddr,
    output logic        memwrite
);

    logic [15:0] pcF;       // PC goes to imem
    logic [15:0] instrF;    // instruction comes back from imem
    logic [15:0] aluoutM;   // ALU result = data memory address
    logic [15:0] readdataM; // data read from dmem (LW)

    logic memreadM, dmem_ready, mem_stall;
    assign mem_stall = (memreadM || memwrite) && !dmem_ready;

    cpu cpuUnit(
        .clk(clk), .reset(reset),
        .Exception_Flag(Exception_Flag),
        .mem_stall(mem_stall),
        .pcF(pcF), .instrF(instrF),
        .memwriteM(memwrite), .memreadM(memreadM),
        .aluoutM(aluoutM),
        .writedataM(writedata), .readdataM(readdataM)
    );


    assign dataaddr = aluoutM;

    imem imemUnit(
        .address(pcF[6:1]),
        .readData(instrF)
    );

    dmem dmemUnit(
        .clk(clk),
        .reset(reset),
        .memRead(memreadM),
        .memWrite(memwrite),
        .address(aluoutM),
        .writeData(writedata),
        .dmem_ready(dmem_ready),
        .readData(readdataM)
    );

endmodule

`endif
// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// Controller
// =======================================================

`ifndef CTRL
`define CTRL

`timescale 1ns/100ps

`include "mainDecoder.sv"
`include "aluDecoder.sv"

module controller(
    input  logic [3:0] op,
    input  logic [3:0] funct,

    output logic       regWrite,
    output logic       memWrite,
    output logic       memToReg,
    output logic       aluSrc,
    output logic [1:0] regDst,
    output logic [1:0] aluOP,
    output logic       branch,
    output logic       branchNe,
    output logic       jump,
    output logic       jumpLink,
    output logic       memBase,
    output logic       branchSrc,
    output logic       flagWrite,
    output logic [3:0] aluCTRL
);

    maindec md(
        .op(op),
        .regWrite(regWrite),
        .memWrite(memWrite),
        .memToReg(memToReg),
        .aluSrc(aluSrc),
        .regDst(regDst),
        .aluOP(aluOP),
        .branch(branch),
        .branchNe(branchNe),
        .jump(jump),
        .jumpLink(jumpLink),
        .memBase(memBase),
        .branchSrc(branchSrc),
        .flagWrite(flagWrite)
    );

    aluDecoder ad(
        .op(op),
        .aluOP(aluOP),
        .funct(funct),
        .aluCTRL(aluCTRL)
    );

endmodule
`endif
// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// CPU
// =======================================================

`ifndef CPU
`define CPU

`timescale 1ns/100ps

`include "controller.sv"
`include "datapath.sv"
`include "hazard.sv"

module cpu(
    input  logic        clk, reset, Exception_Flag, mem_stall,
    
    output logic [15:0] pcF,
    input  logic [15:0] instrF,

    output logic        memwriteM,
    output logic [15:0] aluoutM, writedataM,
    input  logic [15:0] readdataM,
    output logic        memreadM
);

    logic        regwriteD, memwriteD, memtoregD;
    logic        alusrcD;
    logic [1:0]  regdstD;
    logic        branchD, branchneD;
    logic        jumpD, jumplinkD;
    logic        membaseD, branchsrcD;
    logic        flagwriteD;
    logic [3:0]  alucontrolD;

    logic        stallF, stallD, stallE, stallM, stallW;
    logic        flushD, flushE;
    logic        forwardaD, forwardbD;
    logic [1:0]  forwardaE, forwardbE;
    logic [3:0]  rsD, rtD, rsE, rtE;
    logic [3:0]  writeregE, writeregM, writeregW;
    logic        regwriteE, regwriteM, regwriteW;
    logic        memtoregE, memtoregM;
    logic [15:0] instrD;

    assign memreadM = memtoregM;

    controller ctrl(
        .op(instrD[15:12]),      // opcode field
        .funct(instrD[3:0]),     // funct field (R-type)
        .regWrite(regwriteD),
        .memWrite(memwriteD),
        .memToReg(memtoregD),
        .aluSrc(alusrcD),
        .regDst(regdstD),
        .aluOP(),                // consumed internally by aluDecoder
        .branch(branchD),
        .branchNe(branchneD),
        .jump(jumpD),
        .jumpLink(jumplinkD),
        .memBase(membaseD),
        .branchSrc(branchsrcD),
        .flagWrite(flagwriteD),
        .aluCTRL(alucontrolD)
    );

    datapath dp(
        .clk(clk), .reset(reset),
        .pcF(pcF), .instrF(instrF),
        .aluoutM(aluoutM), .writedataM(writedataM),
        .readdataM(readdataM), .memwriteM_out(memwriteM),
        .regwriteD(regwriteD), .memwriteD(memwriteD), .memtoregD(memtoregD),
        .alusrcD(alusrcD), .regdstD(regdstD),
        .branchD(branchD), .branchneD(branchneD),
        .jumpD(jumpD), .jumplinkD(jumplinkD),
        .membaseD(membaseD), .branchsrcD(branchsrcD),
        .flagwriteD(flagwriteD), .alucontrolD(alucontrolD),
        .instrD(instrD),
        .stallF(stallF), .stallD(stallD), .stallE(stallE),
        .stallM(stallM), .stallW(stallW),
        .flushD(flushD), .flushE(flushE),
        .forwardaD(forwardaD), .forwardbD(forwardbD),
        .forwardaE(forwardaE), .forwardbE(forwardbE),
        .rsD(rsD), .rtD(rtD), .rsE(rsE), .rtE(rtE),
        .writeregE(writeregE), .writeregM(writeregM), .writeregW(writeregW),
        .regwriteE(regwriteE), .regwriteM(regwriteM), .regwriteW(regwriteW),
        .memtoregE(memtoregE), .memtoregM(memtoregM),
        .Exception_Flag(Exception_Flag)
    );

    hazard hu(
        .rsD(rsD), .rtD(rtD), .rsE(rsE), .rtE(rtE),
        .writeregE(writeregE), .writeregM(writeregM), .writeregW(writeregW),
        .regwriteE(regwriteE), .regwriteM(regwriteM), .regwriteW(regwriteW),
        .memtoregE(memtoregE), .memtoregM(memtoregM),
        .mem_stall(mem_stall),
        .branchD(branchD), .branchneD(branchneD),
        .Exception_Flag(Exception_Flag),
        .forwardaD(forwardaD), .forwardbD(forwardbD),
        .forwardaE(forwardaE), .forwardbE(forwardbE),
        .stallF(stallF), .stallD(stallD), .stallE(stallE),
        .stallM(stallM), .stallW(stallW),
        .flushD(flushD), .flushE(flushE)
    );

endmodule

`endif
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
// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// data memory
// =======================================================

`ifndef DMEM
`define DMEM

`timescale 1ns/100ps

module dmem #(parameter LATENCY = 5)( 
    input  logic         clk, reset, memRead, memWrite, // write Enable
    input  logic [15:0]  address,
    // address to store (in dmem) 
    // * this does not really need to match with imem size but for simplicity
    input  logic [15:0]  writeData,    // Data to store
    output logic         dmem_ready,
    output logic [15:0]  readData      // loading data from memory
);

    logic [15:0] RAM [0:63]; //2^6 = 64, 64-1

    initial begin
        for (int i = 0; i < 64; i = i + 1)
            RAM[i] = 16'b0;
    end
 
    logic [3:0] delayCounter;


    always_ff @(posedge clk) begin
        if (reset) begin
            delayCounter <= 0;
            dmem_ready <= 0;
        end else begin
            if (memRead || memWrite) begin
                if (delayCounter == LATENCY - 1) begin
                    dmem_ready <= 1;
                    delayCounter <= 0;
                    if (memWrite)
                        RAM[address[6:1]] <= writeData;
                end else begin
                    dmem_ready <= 0;
                    delayCounter <= delayCounter + 1;
                end
            end else begin
                dmem_ready <= 0;
                delayCounter <= 0;
            end
        end
    end

    assign readData = RAM[address[6:1]];

endmodule

`endif
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
    input logic mem_stall
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
    assign stallF = lwstall || branchstall || mem_stall;
    assign stallD = lwstall || branchstall || mem_stall;

    // EX/MEM/WB doesn't need to stall
    assign stallE = mem_stall;
    assign stallM = mem_stall;
    assign stallW = mem_stall;

    assign flushD = Exception_Flag && !mem_stall;

    // flushE : bubble into ID/EX
    assign flushE = (lwstall || branchstall || Exception_Flag) && !mem_stall;

endmodule

`endif
// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// instruction memory
// =======================================================

`ifndef IMEM
`define IMEM

`timescale 1ns/100ps

module imem(
    input logic [5:0] address,      // instruction address, 6bits (2^6 for now)
    output logic [15:0] readData    // 16-bit instruction
);

    logic [15:0] RAM [0:63]; //2^6 = 64, 64-1

    integer i;

    initial begin
        for (i = 0; i < 64; i = i + 1)
            RAM[i] = 16'hF000;   // NOP

        $readmemh("../programs/program", RAM);
    end

    assign readData = RAM[address]; // word aligned

endmodule

`endif
// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// main decoder
// =======================================================

`ifndef MAINDEC
`define MAINDEC

`timescale 1ns/100ps

`include "opcode.sv"

module maindec(
    input  logic [3:0] op,

    output logic       regWrite,
    output logic       memWrite,
    output logic       memToReg,
    output logic       aluSrc,
    output logic [1:0] regDst,
    output logic [1:0] aluOP,
    output logic       branch,
    output logic       branchNe,
    output logic       jump,
    output logic       jumpLink,
    output logic       memBase,
    output logic       branchSrc,
    output logic       flagWrite
);

    logic [14:0] controls;

    assign {regWrite, memWrite, memToReg, aluSrc,
            regDst, aluOP,
            branch, branchNe, jump, jumpLink,
            memBase, branchSrc, flagWrite} = controls; 

    always_comb begin
        case (op)
            //                     rW mW mR aS  rD  aO  br bN  j jL mB bS fW
            `OP_RTYPE: controls = 15'b1_0_0_0_00_10_0_0_0_0_0_0_1;
            `OP_ADDI:  controls = 15'b1_0_0_1_01_00_0_0_0_0_0_0_0;
            `OP_LW:    controls = 15'b1_0_1_1_01_00_0_0_0_0_1_0_0;
            `OP_SW:    controls = 15'b0_1_0_1_00_00_0_0_0_0_1_0_0;
            `OP_BEQ:   controls = 15'b0_0_0_0_00_01_1_0_0_0_0_1_0;
            `OP_BNE:   controls = 15'b0_0_0_0_00_01_0_1_0_0_0_1_0;
            `OP_J:     controls = 15'b0_0_0_0_00_00_0_0_1_0_0_0_0;
            `OP_JAL:   controls = 15'b1_0_0_0_10_00_0_0_1_1_0_0_0;
            `OP_LI:    controls = 15'b1_0_0_1_01_11_0_0_0_0_0_0_0;
            `OP_ANDI:  controls = 15'b1_0_0_1_01_00_0_0_0_0_0_0_1;
            `OP_ORI:   controls = 15'b1_0_0_1_01_00_0_0_0_0_0_0_1;
            `OP_XORI:  controls = 15'b1_0_0_1_01_00_0_0_0_0_0_0_1;
            `OP_SLTI:  controls = 15'b1_0_0_1_01_00_0_0_0_0_0_0_1;
            `OP_LUI:   controls = 15'b1_0_0_1_01_11_0_0_0_0_0_0_0;
            `OP_JR:    controls = 15'b0_0_0_0_00_00_0_0_0_0_0_0_0;
            `OP_NOP:   controls = 15'b0_0_0_0_00_00_0_0_0_0_0_0_0;
            default:   controls = 15'b0_0_0_0_00_00_0_0_0_0_0_0_0;
        endcase
    end
endmodule
`endif
// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// 2:1 mux 
// =======================================================

`ifndef MUX2
`define MUX2

`timescale 1ns/100ps

module mux2 #(parameter n = 16) (
    input   logic [n-1:0] d0,        //input 1 
    input   logic [n-1:0] d1,        //input 2
    input   logic        s,         //selection pin
    output  logic [n-1:0] data_out
);

   assign data_out = s ? d1 : d0;

endmodule

`endif
// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// 4:1 mux 
// =======================================================

`ifndef MUX4
`define MUX4

`timescale 1ns/100ps

module mux4 #(parameter n = 16)(
    input   logic [n-1:0] d0,
    input   logic [n-1:0] d1,
    input   logic [n-1:0] d2,
    input   logic [n-1:0] d3,
    input   logic [1:0]  s, //2bit selection pin
    output  logic [n-1:0] data_out
);

    logic [n-1:0] result_01;
    logic [n-1:0] result_23;

    mux2 #(n)u1(.d0(d0), .d1(d1), .s(s[0]), .data_out(result_01));
    mux2 #(n)u2(.d0(d2), .d1(d3), .s(s[0]), .data_out(result_23));

    mux2 #(n)u3(.d0(result_01), .d1(result_23), .s(s[1]), .data_out(data_out));

endmodule

`endif
// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// OPCODE and FUNCTION FIELD(for R-Type) is declared here.
// =======================================================
`ifndef OPCODE
`define OPCODE

// ── OPCODES ──
// top 4 bits of every instruction [15:12]
`define OP_RTYPE  4'b0000  // R-type: use funct field [3:0] to determine operation
`define OP_ADDI   4'b0001  // R[rd] = R[rd] + signext(imm8)
`define OP_LW     4'b0010  // R[rd] = MEM[R9 + signext(imm8)]
`define OP_SW     4'b0011  // MEM[R9 + signext(imm8)] = R[rd]
`define OP_BEQ    4'b0100  // if R0 == R[rd], PC = PC+2 + signext(imm8)<<1
`define OP_BNE    4'b0101  // if R0 != R[rd], PC = PC+2 + signext(imm8)<<1
`define OP_J      4'b0110  // PC = {PC+2[15:13], imm12, 1'b0}
`define OP_JAL    4'b0111  // R15 = PC+2, PC = {PC+2[15:13], imm12, 1'b0}
`define OP_LI     4'b1000  // R[rd] = signext(imm8)
`define OP_ANDI   4'b1001  // R[rd] = R[rd] & signext(imm8)
`define OP_ORI    4'b1010  // R[rd] = R[rd] | signext(imm8)
`define OP_XORI   4'b1011  // R[rd] = R[rd] ^ signext(imm8)
`define OP_SLTI   4'b1100  // R[rd] = (R[rd] < signext(imm8)) ? 1 : 0
`define OP_LUI    4'b1101  // R[rd] = {imm8, 8'b0} (load upper immediate)
`define OP_JR     4'b1110  // PC = R[rd] 
`define OP_NOP    4'b1111  // no operation

// ── FUNCTION FIELDS for R-TYPE ──
// last 4 bits of R-type instruction [3:0]
// made it to match aluCTRL values so funct can be passed directly to ALU
`define R_AND     4'b0000  // R0 = R[rs] & R[rt]
`define R_OR      4'b0001  // R0 = R[rs] | R[rt]
`define R_ADD     4'b0010  // R0 = R[rs] + R[rt]
`define R_NOR     4'b0011  // R0 = ~(R[rs] | R[rt])
`define R_MFLO    4'b0100  // R0 = HiLo[15:0]  (lower half of multiply result)
`define R_MFHI    4'b0101  // R0 = HiLo[31:16] (upper half of multiply result)
`define R_SUB     4'b0110  // R0 = R[rs] - R[rt]
`define R_SLT     4'b0111  // R0 = (R[rs] < R[rt]) ? 1 : 0
`define R_XOR     4'b1000  // R0 = R[rs] ^ R[rt]
`define R_SLL     4'b1001  // R0 = R[rs] << R[rt][3:0]
`define R_SRL     4'b1010  // R0 = R[rs] >> R[rt][3:0]
`define R_MUL     4'b1011  // HiLo  = R[rs] * R[rt] (use MFLO/MFHI to read result)
`define R_PASSB   4'b1100  // R0 = R[rt]  (pass B through ALU)
`define R_PASSA   4'b1101  // R0 = R[rs]  (pass A through ALU)
`define R_NOT     4'b1110  // R0 = ~R[rs]
`define R_NEG     4'b1111  // R0 = -R[rs] (two's complement)

`endif
// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// register file 
// =======================================================

`ifndef REGFILE
`define REGFILE

`timescale 1ns/100ps

module registerFile(
    input logic        clk,
    input logic        writeEnable, // enable writing

    input logic [3:0]  readReg1,    // Firt reg to read
    input logic [3:0]  readReg2,    // Second reg to read
    input logic [3:0]  writeReg,    // Destination
    input logic [15:0] writeData,   // Data that's going to be stored in Destination

    output logic [15:0] readData1,  // output of readReg1
    output logic [15:0] readData2,  // output of readReg2

    input logic         flagWrite,
    input logic  [15:0] flagsData
);

    // creating registerFile
    // 16 of 16 bit register
    logic [15:0] registers [0:15];

    integer i;

    initial begin
        for (i = 0; i < 16; i = i + 1)
            registers[i] = 16'b0;
    end

    // Unlike MIPS, our Register 0 is Accumulator, so we should be able to write on that register
    always_ff @(negedge clk) begin
        if (writeEnable)
            registers[writeReg] <= writeData;
        if (flagWrite)
            registers[12] <= flagsData;
    end

    assign readData1 = registers[readReg1];
    assign readData2 = registers[readReg2];

endmodule

`endif
// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// Sign Extension
// =======================================================

`ifndef SIGNEXTEND
`define SIGNEXTEND

`timescale 1ns/100ps

module signExtend(
    input logic  [7:0]   A,
    output logic [15:0]  Y
);
    assign Y = { {8{A[7]}}, A };

endmodule

`endif
// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// SL1
// =======================================================

`ifndef SL1
`define SL1

`timescale 1ns/100ps

module sl1(
    input  logic [15:0] A,
    output logic [15:0] Y
);
    assign Y = {A[14:0], 1'b0};
endmodule

`endif
`ifndef TB_COMPUTER
`define TB_COMPUTER

`timescale 1ns/100ps

`include "computer.sv"

module tb_computer;

    logic        clk, reset;
    logic        Exception_Flag;
    logic [15:0] writedata, dataaddr;
    logic        memwrite;

    computer dut(
        .clk(clk),
        .reset(reset),
        .Exception_Flag(Exception_Flag),
        .writedata(writedata),
        .dataaddr(dataaddr),
        .memwrite(memwrite)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    function string instr_name(input logic [15:0] instr);

        if ($isunknown(instr)) begin
            instr_name = "----";
        end else begin
            case (instr[15:12])
                4'h0: begin
                    case (instr[3:0])
                        4'h0: instr_name = "AND ";
                        4'h1: instr_name = "OR  ";
                        4'h2: instr_name = "ADD ";
                        4'h3: instr_name = "NOR ";
                        4'h4: instr_name = "MFLO";
                        4'h5: instr_name = "MFHI";
                        4'h6: instr_name = "SUB ";
                        4'h7: instr_name = "SLT ";
                        4'h8: instr_name = "XOR ";
                        4'h9: instr_name = "SLL ";
                        4'ha: instr_name = "SRL ";
                        4'hb: instr_name = "MUL ";
                        4'hc: instr_name = "PASSB";
                        4'hd: instr_name = "PASSA";
                        4'he: instr_name = "NOT ";
                        4'hf: instr_name = "NEG ";
                        default: instr_name = "R?? ";
                    endcase
                end

                4'h1: instr_name = "ADDI";
                4'h2: instr_name = "LW  ";
                4'h3: instr_name = "SW  ";
                4'h4: instr_name = "BEQ ";
                4'h5: instr_name = "BNE ";
                4'h6: instr_name = "J   ";
                4'h7: instr_name = "JAL ";
                4'h8: instr_name = "LI  ";
                4'h9: instr_name = "ANDI";
                4'ha: instr_name = "ORI ";
                4'hb: instr_name = "XORI";
                4'hc: instr_name = "SLTI";
                4'hd: instr_name = "LUI ";
                4'he: instr_name = "JR  ";
                4'hf: instr_name = "NOP ";
                default: instr_name = "----";
            endcase
        end

    endfunction

    task print_header;
        $display("");
        $display("========================================================================================================================================================================================");
        $display("cyc | pcF  | instrF | name  | instrD | name  | aluoutM | wdataM | mw mr | ready mstall | R0   R1   R2   R3   R4   R5   R9   R12  R15  | fwdD | stallF stallD stallE stallM stallW flushE");
        $display("========================================================================================================================================================================================");
    endtask

    task print_row(input int cycle);
        $display(
            "%3d | %04h | %04h   | %-5s | %04h   | %-5s | %04h    | %04h   | %1b  %1b |   %1b      %1b   | %04h %04h %04h %04h %04h %04h %04h %04h %04h | %1b%1b   |   %1b      %1b      %1b      %1b      %1b      %1b",
            cycle,

            // Fetch / Decode
            dut.cpuUnit.pcF,
            dut.cpuUnit.instrF,
            instr_name(dut.cpuUnit.instrF),
            dut.cpuUnit.dp.instrD,
            instr_name(dut.cpuUnit.dp.instrD),

            // Memory stage
            dut.cpuUnit.dp.aluoutM,
            dut.cpuUnit.dp.writedataM,
            dut.memwrite,
            dut.memreadM,
            dut.dmem_ready,
            dut.mem_stall,

            // Registers
            dut.cpuUnit.dp.rf.registers[0],
            dut.cpuUnit.dp.rf.registers[1],
            dut.cpuUnit.dp.rf.registers[2],
            dut.cpuUnit.dp.rf.registers[3],
            dut.cpuUnit.dp.rf.registers[4],
            dut.cpuUnit.dp.rf.registers[5],
            dut.cpuUnit.dp.rf.registers[9],
            dut.cpuUnit.dp.rf.registers[12],
            dut.cpuUnit.dp.rf.registers[15],

            // Forwarding / stalls / flush
            dut.cpuUnit.dp.forwardaD,
            dut.cpuUnit.dp.forwardbD,
            dut.cpuUnit.hu.stallF,
            dut.cpuUnit.hu.stallD,
            dut.cpuUnit.hu.stallE,
            dut.cpuUnit.hu.stallM,
            dut.cpuUnit.hu.stallW,
            dut.cpuUnit.hu.flushE
        );
    endtask

    initial begin
        $dumpfile("tb_computer.vcd");
        $dumpvars(0, tb_computer);

        Exception_Flag = 0;
        reset = 1;

        @(posedge clk);
        @(posedge clk);
        #1;
        reset = 0;

        print_header();

        for (int cycle = 1; cycle <= 150; cycle++) begin
            @(negedge clk);
            #1;
            print_row(cycle);
        end

        $display("========================================================================================================================================================================================");
        $finish;
    end

    initial begin
        #10000;
        $display("TIMEOUT");
        $finish;
    end

    // This prints only when the delayed memory operation actually finishes.
    always @(negedge clk) begin
        if (dut.dmem_ready && dut.memwrite) begin
            $display("  --> SW COMMIT: MEM[%04h] = %04h", dataaddr, writedata);
        end
    end

    // Optional: print when a load completes too.
    always @(negedge clk) begin
        if (dut.dmem_ready && dut.memreadM) begin
            $display("  --> LW COMPLETE: MEM[%04h] -> %04h", dataaddr, dut.dmemUnit.readData);
        end
    end

endmodule

`endif
