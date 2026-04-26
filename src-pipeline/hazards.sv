`ifndef HAZARD
`define HAZARD

`timescale 1ns/100ps

module hazard (
    input logic [3:0] id_rs,
    input logic [3:0] id_rt,

    input logic [3:0] ex_writeReg,  //destination of instruciton in EX
    input logic       ex_memRead,   // is Ex stage a lw
    input logic       ex_regWrite,  //does ex stage write a register?

    input logic [3:0] mem_writeReg, //destination of instrucion in mem
    input logic       mem_regWrite, //does MEM stage write a register

    input logic       id_branch, //BEQ or BNE in ID
    input logic       id_jump,   //J or JAL in ID


    output logic      stall,     
    output logic      flush_ifid,
    output logic      flush_idex
);

logic load_use_hazard;
assign load_use_hazard = ex_memRead &
                         ((ex_writeReg == id_rs) |
                           (ex_writeReg == id_rt));

logic branch_hazard;
logic jump_hazard;
assign branch_hazard = id_branch;
assign jump_hazard   = id_jump;

logic fwd_ex_rs, fwd_ex_rt;
assign fwd_ex_rs = ex_regWrite & (ex_writeReg != 4'd0) &
                   (ex_writeReg == id_rs);
assign fwd_ex_rt = ex_regWrite & (ex_writeReg != 4'd0) &
                   (ex_writeReg == id_rt);

logic fwd_mem_rs, fwd_mem_rt;
assign fwd_mem_rs = mem_regWrite & (mem_writeReg != 4'd0) &
                    (mem_writeReg == id_rs);
assign fwd_mem_rt = mem_regWrite & (mem_writeReg != 4'd0) &
                    (mem_writeReg == id_rt);

assign stall      = load_use_hazard;

assign flush_ifid = branch_hazard | jump_hazard;
assign flush_idex = branch_hazard;

endmodule

`endif