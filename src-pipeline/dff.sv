`ifndef dff
`define dff

`timescale 1ns/100ps

module dff #(parameter WIDTH = 16) (
    input logic         clk,
    input logic         reset,
    input logic         enable,
    input logic         flush,
    input logic [WIDTH-1:0] D,
    output logic [WIDTH-1:0] Q
);
    always_ff @(posedge clk) begin
        if (reset | flush)
            Q <= {WIDTH{1'b0}};
        else if (enable)
            Q <= D;
    end
endmodule