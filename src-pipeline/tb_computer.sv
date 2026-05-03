`ifndef TB_COMPUTER
`define TB_COMPUTER

`timescale 1ns/100ps

`include "computer.sv"

module tb_computer();

    logic        clk, reset;
    logic [15:0] writeData;
    logic [15:0] dataAddress;
    logic        memWrite;

    computer dut (
        .clk(clk),
        .reset(reset),
        .writeData(writeData),
        .dataAddress(dataAddress),
        .memWrite(memWrite)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task reset_system;
        begin
            reset = 1;
            @(posedge clk);
            @(posedge clk);
            reset = 0;
            $display("System reset complete");
        end
    endtask

    task run_cycles;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1) begin
                @(posedge clk);
                $display("Cycle %0d | PC=%h | memWrite=%b | addr=%h | data=%h",
                    i, dut.cpuUnit.dp.pc,
                    memWrite, dataAddress, writeData);
            end
        end
    endtask

    task print_registers;
        integer i;
        begin
            $display("========= REGISTER FILE =========");
            for (i = 0; i < 16; i = i + 1)
                $display("R%0d = %h", i, dut.cpuUnit.dp.rf.registers[i]);
            $display("=================================");
        end
    endtask

    initial begin
        $display("Starting basic pipeline test...");
        reset_system();
        $display("--- Running 20 cycles ---");
        run_cycles(20);
        print_registers();
        $display("Basic pipeline test complete");
        $finish;
    end

    initial begin
        #10000;
        $display("TIMEOUT");
        $finish;
    end

    initial begin
        $dumpfile("pipeline.vcd");
        $dumpvars(0, tb_computer);
    end

endmodule

`endif