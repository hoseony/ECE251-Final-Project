//////////////////////////////////////////////////////////////////////////////////
// The Cooper Union
// ECE 251 Spring 2026
// Engineer: Prof Rob Marano
// 
//     Create Date: 2026-04-09
//     Module Name: computer
//     Description: 32-bit Pipelined CPU mapping to I-Mem and D-Mem
//////////////////////////////////////////////////////////////////////////////////


`include "cpu.sv"
`include "imem.sv"
`include "dmem.sv"

module computer(
    input  logic        clk, reset,
    output logic [31:0] writedata, dataadr,
    output logic        memwrite
);
    logic [31:0] pc, instr, readdata;

    // CPU instantiation
    cpu mips_pipelined(
        .clk(clk), .reset(reset),
        .pcF(pc), .instrF(instr),
        .memwriteM(memwrite), .aluoutM(dataadr),
        .writedataM(writedata), .readdataM(readdata)
    );

    // Instruction Memory
    imem imem(
        .addr(pc[7:2]),
        .readdata(instr)
    );

    // Data Memory
    dmem dmem(
        .clk(clk), .write_enable(memwrite),
        .addr(dataadr),
        .writedata(writedata),
        .readdata(readdata)
    );

endmodule

