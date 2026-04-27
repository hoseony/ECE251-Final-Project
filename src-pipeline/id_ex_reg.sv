`ifndef ID_EX_REG
`define ID_EX_REG

`timescale 1ns/100ps
`include "dff.sv"

module id_ex_reg(
    input logic         clk,
    input logic         reset,
    input logic         enable,
    input logic         flush,
    
    input logic[15:0]   id_pc_plus2, //pc
    //control signals form controller
    input logic         id_regWrite,
    input logic         id_memWrite,
    input logic         id_memToReg,
    input logic         id_memRead,
    input logic         id_aluSrc,
    input logic         id_jump,
    input logic         id_jumpLink,
    input logic         id_memBase,
    input logic         id_branchSrc,
    input logic         id_flagWrite,
    input logic [1:0]   id_regDst,
    input logic [3:0]   id_aluCTRL,

    //id data
    input logic [15:0]  id_readData1,
    input logic [15:0]  id_readData2,
    input logic [15:0]  id_signImm,

    //regtags for fowarding and write back
    input logic [3:0]   id_rs,
    input logic [3:0]   id_rt,
    input logic [3:0]   id_rd,
    //output to ex
    output logic [15:0] ex_pc_plus2,

    output logic         ex_regWrite,
    output logic         ex_memWrite,
    output logic         ex_memToReg,
    output logic        ex_memRead,
    output logic         ex_aluSrc,
    output logic         ex_jump,
    output logic         ex_jumpLink,
    output logic         ex_memBase,
    output logic         ex_branchSrc,
    output logic         ex_flagWrite,
    output logic [1:0]   ex_regDst,
    output logic [3:0]   ex_aluCTRL, 

    output logic [15:0]  ex_readData1,
    output logic [15:0]  ex_readData2, 
    output logic [15:0]  ex_signImm,

    output logic [3:0]   ex_rs,
    output logic [3:0]   ex_rt,
    output logic [3:0]   ex_rd
);
    // PC
    dff #(16) pc_reg      (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(id_pc_plus2),   .Q(ex_pc_plus2));

    // data
    dff #(16) rd1_reg     (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(id_readData1),  .Q(ex_readData1));
    dff #(16) rd2_reg     (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(id_readData2),  .Q(ex_readData2));
    dff #(16) simm_reg    (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(id_signImm),    .Q(ex_signImm));

    // register tags 
    dff #(4)  rs_reg      (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(id_rs),         .Q(ex_rs));
    dff #(4)  rt_reg      (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(id_rt),         .Q(ex_rt));
    dff #(4)  rd_reg      (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(id_rd),         .Q(ex_rd));

    // control signals 
    dff #(1)  regw_reg    (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(id_regWrite),   .Q(ex_regWrite));
    dff #(1)  memw_reg    (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(id_memWrite),   .Q(ex_memWrite));
    dff #(1)  memtr_reg   (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(id_memToReg),   .Q(ex_memToReg));
    dff #(1)  memrd_reg   (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(id_memRead),    .Q(ex_memRead));
    dff #(1)  alus_reg    (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(id_aluSrc),     .Q(ex_aluSrc));
    dff #(1)  jmp_reg     (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(id_jump),       .Q(ex_jump));
    dff #(1)  jmpl_reg    (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(id_jumpLink),   .Q(ex_jumpLink));
    dff #(1)  memb_reg    (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(id_memBase),    .Q(ex_memBase));
    dff #(1)  bsrc_reg    (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(id_branchSrc),  .Q(ex_branchSrc));
    dff #(1)  flagw_reg   (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(id_flagWrite),  .Q(ex_flagWrite));

    // 2-bit control signals
    dff #(2)  rdst_reg    (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(id_regDst),     .Q(ex_regDst));

    // 4-bit control signals 
    dff #(4)  aluc_reg    (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(id_aluCTRL),    .Q(ex_aluCTRL));

endmodule

`endif
