`include "_timescale.sv"
//////////////////////////////////////////////////////////////////////////////////
// The Cooper Union
// ECE 251 Spring 2026
// Engineer: Prof Rob Marano
// 
//     Create Date: 2026-04-09
//     Module Name: tb_computer
//     Description: Testbench for the Pipelined MIPS CPU
//////////////////////////////////////////////////////////////////////////////////


`include "computer.sv"

module tb_computer;

    logic        clk;
    logic        reset;
    logic [31:0] writedata, dataadr;
    logic        memwrite;
    
    // Instantiate device under test
    computer dut(clk, reset, writedata, dataadr, memwrite);

    // clock signal generation
    initial begin
        $dumpfile("tb_computer.vcd");
        $dumpvars(0, tb_computer);
        clk = 0;
    end

    always begin
        #5 clk = ~clk;
    end

    // initial stimulus
    initial begin
        $display("Initializing testbench simulation...");
        reset = 1; #22;
        reset = 0;
    end

    initial begin
        #2000;
        $display("Testbench timeout");
        $finish;
    end

    // checking the results mathematically at memory writes
    always @(negedge clk) begin
        if (memwrite) begin
            if (dataadr === 84 && writedata === 12) begin
                $display("Success: mem[84] evaluates to 12. Arithmetic RAW Forwarding logic mapped correctly.");
            end else if (dataadr === 88 && writedata === 24) begin
                $display("Extravagant Success: mem[88] evaluates to 24. Pipelined Branch Flushes and Load-Use Stalls executed perfectly!");
                $finish;
            end
        end
    end

endmodule

