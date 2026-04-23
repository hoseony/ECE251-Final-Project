//////////////////////////////////////////////////////////////////////////////////
// The Cooper Union
// ECE 251 Spring 2023
// Engineer: Prof Rob Marano
// 
//     Create Date: 2023-02-07
//     Module Name: mem
//     Description: 32-bit RISC Unified Memory (Instructions + Data)
//
//////////////////////////////////////////////////////////////////////////////////
`ifndef MEM
`define MEM

`timescale 1ns/100ps

module mem
    #(parameter n = 32, parameter r = 6)(
    input  logic           clk, we,
    input  logic [(n-1):0] a, wd,
    output logic [(n-1):0] rd
);
    logic [(n-1):0] RAM[0:(2**r-1)];

    initial begin
        $readmemh("../programs/mult-prog_exe", RAM);
    end

    assign rd = RAM[a[(n-1):2]]; // word aligned

    always @(posedge clk)
        if (we) RAM[a[(n-1):2]] <= wd;

endmodule

`endif // MEM
