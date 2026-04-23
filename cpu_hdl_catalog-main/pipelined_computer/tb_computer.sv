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
    logic        intr;
    logic [31:0] writedata, dataadr;
    logic        memwrite;
    
    // Instantiate device under test
    computer dut(clk, reset, intr, writedata, dataadr, memwrite);

    // clock signal generation
    initial begin
        $dumpfile("tb_computer.vcd");
        $dumpvars(0, tb_computer);
        clk = 0;
        intr = 0;
    end

    always begin
        #5 clk = ~clk;
    end

    // Cycle-by-cycle logging for educational trace routing
    integer cycle = 0;
    always @(posedge clk) begin
        if (!reset) begin
            cycle++;
            $display("╭─────────────────────────────────────────────────────────────────────────────────────────────────╮");
            $display("│ %-95s │", $sformatf("Cycle %0d (Time: %0t)", cycle, $time));
            $display("│ %-95s │", $sformatf("  [IF]   PC: 0x%08h | StallF: %b", dut.mips_pipelined.dp.pcF, dut.mips_pipelined.stallF));
            $display("│ %-95s │", $sformatf("  [ID]   Instr: 0x%08h | rs: %2d, rt: %2d | StallD: %b | FlushD: %b | Branch: %b", dut.mips_pipelined.dp.instrD, dut.mips_pipelined.dp.rsD, dut.mips_pipelined.dp.rtD, dut.mips_pipelined.stallD, dut.mips_pipelined.flushD, dut.mips_pipelined.branchD));
            $display("│ %-95s │", $sformatf("  [EX]   ALUOut: 0x%08h | FlushE: %b | EPC: 0x%08h", dut.mips_pipelined.dp.aluoutE, dut.mips_pipelined.flushE, dut.mips_pipelined.dp.EPC));
            $display("│ %-95s │", $sformatf("  [MEM]  MemWrite: %b | Addr: 0x%08h | WriteData: 0x%08h", memwrite, dataadr, writedata));
            $display("│ %-95s │", $sformatf("  [WB]   RegWrite: %b | RegDst: %2d | ResultW: 0x%08h", dut.mips_pipelined.dp.regwriteW, dut.mips_pipelined.dp.writeregW, dut.mips_pipelined.dp.resultW));
            $display("╰─────────────────────────────────────────────────────────────────────────────────────────────────╯");
        end
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
            
            // Universal Memory-Mapped I/O Halt
            if (dataadr === 252) begin
                $display("╭─────────────────────────────────────────────────────────────────────────────────────────────────╮");
                $display("│ %-95s │", "Program gracefully halted via Memory-Mapped I/O write to address 252.");
                $display("╰─────────────────────────────────────────────────────────────────────────────────────────────────╯");
                $finish;
            end
        end
    end




endmodule
