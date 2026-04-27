`ifndef IF_ID_REG
`define IF_ID_REG

`timescale 1ns/100ps
`include "dff.sv"
module if_id_reg (
    input logic         clk,
    input logic         reset,
    input logic         enable, //0 - stall
    input logic         flush, //1 = inject bubble
//inputs fromm IF stage
input logic [15:0] if_pc_plus2,
input logic [15:0] if_instr,

//outputs
output logic [15:0] id_pc_plus2,
output logic [15:0] id_instr
);

Dff #(16) pc_reg(//register that store pc +2
    .clk(clk),
    .reset(reset),
    .enabe(enable),
    .flush(flush),
    .D(if_pc_plus2),
    .Q(id_pc_plus2)
);
dff #(16) instr_reg(
    .clk(clk),
    .reset(reset),
    .enabe(enable),
    .flush(flush),
    .D(if_instr),
    .Q(id_instr)
)

endmodule

`endif