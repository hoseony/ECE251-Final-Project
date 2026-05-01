`ifndef MEM_WB_REG
`define MEM_WB_REG

`timescale 1ns/100ps
`include "dff.sv"

module mem_wb_reg(
    input logic     clk,
    input logic     reset,
    input logic     enable,
    input logic     flush,

    input logic [15:0] mem_aluOut,
    input logic [15:0] mem_readData,
    input logic [3:0]  mem_writeReg,

    input logic     mem_regWrite,
    input logic     mem_memToReg,
    input logic     mem_flagWrite,

    output logic [15:0] wb_aluOut,
    output logic [15:0] wb_readData,
    output logic [3:0]  wb_writeReg,
    output logic        wb_regWrite,
    output logic        wb_memToReg,
    output logic        wb_flagWrite
);
//data
    dff #(16) alu_reg  (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(mem_aluOut),    .Q(wb_aluOut));
    dff #(16) rd_reg   (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(mem_readData),  .Q(wb_readData));
//reg tag
    dff #(4)  wreg_reg (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(mem_writeReg),  .Q(wb_writeReg));
//ctrl signals
    dff #(1)  regw_reg (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(mem_regWrite),  .Q(wb_regWrite));
    dff #(1)  memt_reg (.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(mem_memToReg),  .Q(wb_memToReg));
    dff #(1)  flagw_reg(.clk(clk), .reset(reset), .enable(enable), .flush(flush), .D(mem_flagWrite), .Q(wb_flagWrite));
endmodule

`endif