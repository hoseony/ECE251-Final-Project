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
    input  logic         clk, reset,

    input  logic         memRead,
    input  logic         memWrite,

    input  logic [15:0]  address,
    input  logic [15:0]  writeData,

    output logic         dmem_ready,
    output logic [15:0]  readData
);

    logic [15:0] RAM [0:63];

    initial begin
        for (int i = 0; i < 64; i = i + 1)
            RAM[i] = 16'b0;
    end

    logic [3:0] delayCounter;
    logic       memBusy;

    assign memBusy = memRead || memWrite;
    assign dmem_ready = !memBusy || (delayCounter == LATENCY - 1);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            delayCounter <= 4'b0;
        end else begin
            if (memBusy) begin
                if (delayCounter == LATENCY - 1) begin
                    if (memWrite)
                        RAM[address[6:1]] <= writeData;

                    delayCounter <= 4'b0;
                end else begin
                    delayCounter <= delayCounter + 1'b1;
                end
            end else begin
                delayCounter <= 4'b0;
            end
        end
    end

    assign readData = RAM[address[6:1]];

endmodule

`endif
