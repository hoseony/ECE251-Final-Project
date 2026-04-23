`timescale 1ns/1ps

`include "computer.sv"

module tb_exceptions();
    logic clk;
    logic reset;
    logic intr;
    logic [31:0] writedata, dataadr;
    logic memwrite;

    computer dut (
        .clk(clk),
        .reset(reset),
        .intr(intr),
        .writedata(writedata),
        .dataadr(dataadr),
        .memwrite(memwrite)
    );

    initial begin
        $dumpfile("tb_exceptions.vcd");
        $dumpvars(0, tb_exceptions);
        
        reset = 1;
        intr = 0;
        clk = 0;
        
        #10 reset = 0;
        
        #95;
        
        // Assert Interrupt right in the middle of executing loop payload
        $display("[%0t] Asserting Interrupt asynchronously!", $time);
        intr = 1;
        #10;
        intr = 0;
        
        // Wait for OS handler to run and modify $k0 (reg 26)
        #200;
        
        $display("\n--- EXCEPTION REPORT ---");
        if (dut.mips_pipelined.dp.rf.rf[26] === 32'd999) begin
            $display("SUCCESS: OS Exception Handler executed gracefully! $k0 == 999");
        end else begin
            $display("FAIL: Exception Handler did not set $k0! Found: %d", dut.mips_pipelined.dp.rf.rf[26]);
        end
        
        $display("EPC captured PC sequence: 0x%08h", dut.mips_pipelined.dp.EPC);
        $finish;
    end

    always #5 clk = ~clk;

endmodule
