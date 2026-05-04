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
    input  logic         clk, reset, memRead, memWrite, // write Enable
    input  logic [15:0]  address,
    // address to store (in dmem) 
    // * this does not really need to match with imem size but for simplicity
    input  logic [15:0]  writeData,    // Data to store
    output logic         dmem_ready,
    output logic [15:0]  readData      // loading data from memory
);

    logic [15:0] RAM [0:63]; //2^6 = 64, 64-1

    initial begin
        for (int i = 0; i < 64; i = i + 1)
            RAM[i] = 16'b0;
    end
 
    logic [3:0] delayCounter;


    always_ff @(posedge clk) begin
        if (reset) begin
            delayCounter <= 0;
            dmem_ready <= 0;
        end else begin
            if (memRead || memWrite) begin
                if (delayCounter == LATENCY - 1) begin
                    dmem_ready <= 1;
                    delayCounter <= 0;
                    if (memWrite)
                        RAM[address[6:1]] <= writeData;
                end else begin
                    dmem_ready <= 0;
                    delayCounter <= delayCounter + 1;
                end
            end else begin
                dmem_ready <= 0;
                delayCounter <= 0;
            end
        end
    end

    assign readData = RAM[address[6:1]];

endmodule

`endif
