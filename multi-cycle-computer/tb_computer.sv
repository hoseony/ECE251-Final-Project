`timescale 1ns/100ps
`include "computer.sv"

module tb_computer();
    logic        clk, reset;
    logic [15:0] writeData, dataAddress;
    logic        memWrite;

    computer dut(.clk(clk), .reset(reset), .writeData(writeData), 
                 .dataAddress(dataAddress), .memWrite(memWrite));

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        reset = 1;
        @(posedge clk);
        @(posedge clk);
        reset = 0;
        repeat(50) @(posedge clk);
        $display("R0 = %h", dut.cpuUnit.dp.rf.registers[0]);
        $display("R1 = %h", dut.cpuUnit.dp.rf.registers[1]);
        $finish;
    end
endmodule
