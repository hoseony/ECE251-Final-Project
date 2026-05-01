`ifndef EX_MEM_REG
`define EX_MEM_REG

`timescale 1ns/100ps
`include "dff.sv"

module ex_mem_reg (
    input logic         clk,
    input logic         reset,
    input logic         enable,
    input logic         flush,
// data form ex stage
    input logic [15:0] ex_aluOut,
    input logic [15:0] ex_writeData,
    input logic [3:0]  ex_writeReg,

//control singnals that mem/wb will need
    input logic         ex_regWrite,
    input logic         ex_memWrite,
    input logic         ex_memToReg,
    input logic         ex_memRead,
    input logic         ex_flagWrite,

    //outputs to mem stage

    output logic [15:0] mem_aluOut,
    output logic [15:0] mem_writeData,
    output logic [3:0]  mem_writeReg,

    output logic        mem_regWrite,
    output logic        mem_memWrite,
    output logic        mem_memToReg,
    output logic        mem_memRead,
    output logic        mem_flagWrite
);

//data
    dff #(16) alu_reg  (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(ex_aluOut),    .Q(mem_aluOut));
    dff #(16) wd_reg   (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(ex_writeData), .Q(mem_writeData));
//register tag
    dff #(4)  wreg_reg (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(ex_writeReg),  .Q(mem_writeReg));
//ctrl signals
    dff #(1)  regw_reg (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(ex_regWrite),  .Q(mem_regWrite));
    dff #(1)  memw_reg (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(ex_memWrite),  .Q(mem_memWrite));
    dff #(1)  memt_reg (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(ex_memToReg),  .Q(mem_memToReg));
    dff #(1)  memr_reg (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(ex_memRead),   .Q(mem_memRead));
    dff #(1)  flagw_reg(.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(ex_flagWrite), .Q(mem_flagWrite));

endmodule 

`endif