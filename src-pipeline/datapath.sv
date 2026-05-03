`ifndef DATAPATH
`define DATAPATH

`timescale 1ns/100ps

`include "../src-multi-cycle/adder.sv"
`include "../src-multi-cycle/alu.sv"
`include "../src-multi-cycle/mux2.sv"
`include "../src-multi-cycle/mux4.sv"
`include "../src-multi-cycle/signExtend.sv"
`include "../src-multi-cycle/registerFile.sv"
`include "../src-multi-cycle/sl1.sv"
`include "dff.sv"
`include "if_id_reg.sv"
`include "id_ex_reg.sv"
`include "ex_mem_reg.sv"
`include "mem_wb_reg.sv"

module datapath (
    input  logic        clk, reset,

    input  logic [15:0] if_instr,

    input  logic        regWrite,
    input  logic        memToReg,
    input  logic        memRead,
    input  logic        memWrite,
    input  logic        aluSrc,
    input  logic        jump,
    input  logic        jumpLink,
    input  logic        memBase,
    input  logic        branchSrc,
    input  logic        flagWrite,
    input  logic [1:0]  regDst,
    input  logic [3:0]  aluCTRL,

    // hazard unit
    input  logic        stall,
    input  logic        flush_ifid,
    input  logic        flush_idex,

    // from memory
    input  logic [15:0] readData,

    output logic [15:0] instrOut,
    output logic [15:0] pc,
    output logic [15:0] aluOut,
    output logic [15:0] writeData,
    output logic        memWriteOut,
    output logic [15:0] dataAddress,

    output logic [3:0]  id_rs_out,
    output logic [3:0]  id_rt_out,
    output logic [3:0]  ex_writeReg_out,
    output logic        ex_memRead_out,
    output logic        ex_regWrite_out,
    output logic [3:0]  mem_writeReg_out,
    output logic        mem_regWrite_out,
    output logic        id_branch_out,
    output logic        id_jump_out,
    output logic        zero_out
);

// ===================== IF STAGE =====================
    logic [15:0] pcNext;
    logic [15:0] pcPlus2;    


    dff #(16) pcReg (
        .clk(clk),
        .reset(reset),
        .enable(~stall),    
        .flush(1'b0),       
        .D(pcNext),
        .Q(pc)
    );

  
    adder pcAdd (.A(pc), .B(16'd2), .Y(pcPlus2));
    // ===================== IF/ID REGISTER =====================
    logic [15:0] id_pc_plus2;
    logic [15:0] id_instr;

    if_id_reg ifid (
        .clk(clk),
        .reset(reset),
        .enable(~stall),
        .flush(flush_ifid),
        .if_pc_plus2(pcPlus2),
        .if_instr(if_instr),
        .id_pc_plus2(id_pc_plus2),
        .id_instr(id_instr)
    );

    // ===================== ID STAGE =====================
    // register file read
    logic [3:0]  id_rs, id_rt, id_rd;
    logic [15:0] id_readData1, id_readData2;
    logic [15:0] id_signImm, id_signImmSh;
    logic [15:0] id_pcBranch;
    logic [15:0] wb_result;     // writeback result 

    // decode register fields from instruction
    // rs: readReg1 — R9 for LW/SW, R0 for branch, else instr[7:4]
    mux4 #(4) rsMux(
        id_instr[7:4],  // 00: normal rs
        4'd9,           // 01: R9 for LW/SW 
        4'd0,           // 10: R0 for branch
        4'd0,           // 11: unused
        {branchSrc, memBase},
        id_rs
    );

    assign id_rt = id_instr[11:8];  // rt is always instr[11:8]
    assign id_rd = id_instr[11:8];  // rd same field for I-type

    // register file — write comes from WB stage
    registerFile rf (
        .clk(clk),
        .writeEnable(wb_regWrite),     
        .readReg1(id_rs),
        .readReg2(id_rt),
        .writeReg(wb_writeReg),         
        .writeData(wb_result),          
        .readData1(id_readData1),
        .readData2(id_readData2),
        .flagWrite(wb_flagWrite),       
        .flagsData(wb_flagsData)        
    );

    // sign extend immediate
    signExtend se (.A(id_instr[7:0]), .Y(id_signImm));
    sl1 immSh (.A(id_signImm), .Y(id_signImmSh));

    // branch target = PC+2 + signImmSh
    adder branchAdd (.A(id_pc_plus2), .B(id_signImmSh), .Y(id_pcBranch));

    // branch/jump signals decoded from opcode
    logic id_branch, id_jump;
    assign id_branch = (id_instr[15:12] == 4'b0100) | 
                       (id_instr[15:12] == 4'b0101); // BEQ or BNE
    assign id_jump   = (id_instr[15:12] == 4'b0110) | 
                       (id_instr[15:12] == 4'b0111); // J or JAL

// ===================== ID/EX REGISTER =====================
    logic [15:0] ex_pc_plus2;
    logic        ex_regWrite, ex_memWrite, ex_memToReg;
    logic        ex_memRead, ex_aluSrc, ex_jump;
    logic        ex_jumpLink, ex_memBase, ex_branchSrc, ex_flagWrite;
    logic [1:0]  ex_regDst;
    logic [3:0]  ex_aluCTRL;
    logic [15:0] ex_readData1, ex_readData2, ex_signImm;
    logic [3:0]  ex_rs, ex_rt, ex_rd;

    id_ex_reg idex (
        .clk(clk),
        .reset(reset),
        .enable(~stall),
        .flush(flush_idex),
        .id_pc_plus2(id_pc_plus2),
        .id_regWrite(regWrite),
        .id_memWrite(memWrite),
        .id_memToReg(memToReg),
        .id_memRead(memRead),
        .id_aluSrc(aluSrc),
        .id_jump(jump),
        .id_jumpLink(jumpLink),
        .id_memBase(memBase),
        .id_branchSrc(branchSrc),
        .id_flagWrite(flagWrite),
        .id_regDst(regDst),
        .id_aluCTRL(aluCTRL),
        .id_readData1(id_readData1),
        .id_readData2(id_readData2),
        .id_signImm(id_signImm),
        .id_rs(id_rs),
        .id_rt(id_rt),
        .id_rd(id_rd),
        .ex_pc_plus2(ex_pc_plus2),
        .ex_regWrite(ex_regWrite),
        .ex_memWrite(ex_memWrite),
        .ex_memToReg(ex_memToReg),
        .ex_memRead(ex_memRead),
        .ex_aluSrc(ex_aluSrc),
        .ex_jump(ex_jump),
        .ex_jumpLink(ex_jumpLink),
        .ex_memBase(ex_memBase),
        .ex_branchSrc(ex_branchSrc),
        .ex_flagWrite(ex_flagWrite),
        .ex_regDst(ex_regDst),
        .ex_aluCTRL(ex_aluCTRL),
        .ex_readData1(ex_readData1),
        .ex_readData2(ex_readData2),
        .ex_signImm(ex_signImm),
        .ex_rs(ex_rs),
        .ex_rt(ex_rt),
        .ex_rd(ex_rd)
    );

    // ===================== EX STAGE =====================
    logic [15:0] ex_srcA, ex_srcB;
    logic [15:0] ex_aluOut;
    logic        ex_zero, ex_negative, ex_carry, ex_overflow;
    logic [3:0]  ex_writeReg;
    logic [15:0] ex_forwardA, ex_forwardB;

    // ---- forwarding muxes ----
    // 00: from register file
    // 01: forward from MEM/WB
    // 10: forward from EX/MEM
    logic [1:0] fwdA, fwdB;

    assign fwdA = (mem_regWrite && (mem_writeReg == ex_rs)) ? 2'b10 :
                  (wb_regWrite  && (wb_writeReg  == ex_rs)) ? 2'b01 :
                  2'b00;

    assign fwdB = (mem_regWrite && (mem_writeReg == ex_rt)) ? 2'b10 :
                  (wb_regWrite  && (wb_writeReg  == ex_rt)) ? 2'b01 :
                  2'b00;

    // 3-way mux for srcA
    always_comb begin
        case (fwdA)
            2'b00:   ex_forwardA = ex_readData1;        // from reg file
            2'b01:   ex_forwardA = wb_result;           // from WB
            2'b10:   ex_forwardA = mem_aluOut;          // from EX/MEM
            default: ex_forwardA = ex_readData1;
        endcase
    end

    // 3-way mux for srcB
    always_comb begin
        case (fwdB)
            2'b00:   ex_forwardB = ex_readData2;        // from reg file
            2'b01:   ex_forwardB = wb_result;           // from WB
            2'b10:   ex_forwardB = mem_aluOut;          // from EX/MEM
            default: ex_forwardB = ex_readData2;
        endcase
    end

    // srcA: ADDI special case
    assign ex_srcA = ex_forwardA;

    // srcB: forwarded register or sign extended immediate
    mux2 #(16) srcBMux (ex_forwardB, ex_signImm, ex_aluSrc, ex_srcB);

    // ALU
    alu aluUnit (
        .clk(clk),
        .a(ex_srcA),
        .b(ex_srcB),
        .aluCTRL(ex_aluCTRL),
        .result(ex_aluOut),
        .zero(ex_zero),
        .negative(ex_negative),
        .carry(ex_carry),
        .overflow(ex_overflow)
    );

    // compute writeReg from regDst
    
    mux4 #(4) wrMux (
        4'd0,           // 00: accumulator
        ex_rd,          // 01: I-type destination
        4'd15,          // 10: $ra for JAL
        4'd0,           // 11: not used
        ex_regDst,
        ex_writeReg
    );

    // j target
    logic [15:0] ex_pcJump;
    assign ex_pcJump = {ex_pc_plus2[15:13], ex_rd, ex_rt, ex_signImm[0], 1'b0};
    // ===================== EX/MEM REGISTER =====================
    logic [15:0] mem_aluOut;
    logic [15:0] mem_writeData;
    logic [3:0]  mem_writeReg;
    logic        mem_regWrite, mem_memWrite, mem_memToReg;
    logic        mem_memRead, mem_flagWrite;

    ex_mem_reg exmem (
        .clk(clk),
        .reset(reset),
        .enable(1'b1),         
        .flush(1'b0),           
        .ex_aluOut(ex_aluOut),
        .ex_writeData(ex_forwardB),  
        .ex_writeReg(ex_writeReg),
        .ex_regWrite(ex_regWrite),
        .ex_memWrite(ex_memWrite),
        .ex_memToReg(ex_memToReg),
        .ex_memRead(ex_memRead),
        .ex_flagWrite(ex_flagWrite),
        .mem_aluOut(mem_aluOut),
        .mem_writeData(mem_writeData),
        .mem_writeReg(mem_writeReg),
        .mem_regWrite(mem_regWrite),
        .mem_memWrite(mem_memWrite),
        .mem_memToReg(mem_memToReg),
        .mem_memRead(mem_memRead),
        .mem_flagWrite(mem_flagWrite)
    );

    // ===================== MEM STAGE =====================
    assign dataAddress = mem_aluOut;
    assign writeData   = mem_writeData;
    assign memWriteOut = mem_memWrite;
// ===================== MEM/WB REGISTER =====================
    logic [15:0] wb_aluOut;
    logic [15:0] wb_readData;
    logic [3:0]  wb_writeReg;
    logic        wb_regWrite, wb_memToReg, wb_flagWrite;

    mem_wb_reg memwb (
        .clk(clk),
        .reset(reset),
        .enable(1'b1),         
        .flush(1'b0),          
        .mem_aluOut(mem_aluOut),
        .mem_readData(readData),
        .mem_writeReg(mem_writeReg),
        .mem_regWrite(mem_regWrite),
        .mem_memToReg(mem_memToReg),
        .mem_flagWrite(mem_flagWrite),
        .wb_aluOut(wb_aluOut),
        .wb_readData(wb_readData),
        .wb_writeReg(wb_writeReg),
        .wb_regWrite(wb_regWrite),
        .wb_memToReg(wb_memToReg),
        .wb_flagWrite(wb_flagWrite)
    );

    // ===================== WB STAGE =====================
    logic [15:0] wb_aluOrMem;
    mux2 #(16) resultMux (
        wb_aluOut,
        wb_readData,
        wb_memToReg,
        wb_aluOrMem
    );

    // JAL: save PC+2 as return address instead of ALU result
    mux2 #(16) jalMux (
        wb_aluOrMem,
        ex_pc_plus2,        
        ex_jumpLink,        
        wb_result
    );

    // flags data for register file
    logic [15:0] wb_flagsData;
    assign wb_flagsData = {12'b0, ex_overflow, ex_carry, ex_negative, ex_zero};

    // ===================== PC NEXT LOGIC =====================
    // decide what PC becomes next cycle
    logic [15:0] pcNextBr;

    
    mux2 #(16) pcBrMux (
        pcPlus2,
        id_pcBranch,
        (ex_zero & ex_branchSrc),   
        pcNextBr
    );

   
    mux2 #(16) pcMux (
        pcNextBr,
        ex_pcJump,
        ex_jump,
        pcNext
    );

 
    assign aluOut = ex_aluOut;
    assign instrOut = id_instr;
    assign id_rs_out        = id_rs;
    assign id_rt_out        = id_rt;
    assign ex_writeReg_out  = ex_writeReg;
    assign ex_memRead_out   = ex_memRead;
    assign ex_regWrite_out  = ex_regWrite;
    assign mem_writeReg_out = mem_writeReg;
    assign mem_regWrite_out = mem_regWrite;
    assign id_branch_out    = id_branch;
    assign id_jump_out      = id_jump;
    assign zero_out         = ex_zero;
endmodule

`endif