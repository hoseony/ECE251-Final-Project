`include "../pipelined_cached_computer/_timescale.sv"
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
    logic        cache_en;
    logic [31:0] writedata, dataadr;
    logic        memwrite;
    
    // Instantiate device under test
    computer dut(clk, reset, intr, cache_en, writedata, dataadr, memwrite);

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

    // Performance Counters
    integer cycle = 0;
    integer instr_count = 0;
    integer cache_hits = 0;
    integer cache_misses = 0;

    always @(posedge clk) begin
        if (!reset) begin
            cycle++;
            
            if (dut.mips_pipelined.dp.instrF != 32'b0 && !dut.mips_pipelined.stallF) begin
                instr_count++;
            end

            // Track Hits and Misses in the Cache module
            // We only count when not stalled in FETCHING state to avoid double counting
            if ((dut.dcache.cpu_memread || dut.dcache.cpu_memwrite) && dut.dcache.state == 0) begin
                if (dut.dcache.hit) cache_hits++;
                if (dut.dcache.miss) cache_misses++;
            end

            if (cycle % 100 == 0) begin
                 $display("Cycle %0d...", cycle);
            end
        end
    end

    // initial stimulus
    initial begin
        if ($test$plusargs("CACHE_EN=1")) begin
            cache_en = 1;
            $display("Starting Simulation: CACHE ENABLED");
        end else begin
            cache_en = 0;
            $display("Starting Simulation: CACHE DISABLED (DIRECT TO MAIN MEMORY)");
        end

        reset = 1; #22;
        reset = 0;
    end

    initial begin
        #100000; // Increased timeout for slow dmem loops
        $display("Testbench timeout");
        $finish;
    end

    // check results and print performance metrics on halt
    always @(negedge clk) begin
        if (memwrite) begin
            // Universal Memory-Mapped I/O Halt
            if (dataadr === 252) begin
                $display("\n╭─────────────────────────────────────────────────────────────────────────────────────────────────╮");
                $display("│ %-95s │", "Program gracefully halted via Memory-Mapped I/O.");
                $display("├─────────────────────────────────────────────────────────────────────────────────────────────────┤");
                $display("│ PERFORMANCE METRICS:                                                                            │");
                $display("│ %-95s │", $sformatf("Total Clock Cycles: %0d", cycle));
                $display("│ %-95s │", $sformatf("Instructions Executed: ~%0d", instr_count));
                $display("│ %-95s │", $sformatf("Effective CPI: %0.2f", real'(cycle) / real'(instr_count)));
                $display("│ %-95s │", $sformatf("Cache Hits: %0d", cache_hits));
                $display("│ %-95s │", $sformatf("Cache Misses: %0d", cache_misses));
                $display("╰─────────────────────────────────────────────────────────────────────────────────────────────────╯\n");
                $finish;
            end
        end
    end

endmodule
