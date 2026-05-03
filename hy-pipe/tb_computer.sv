`ifndef TB_COMPUTER
`define TB_COMPUTER

`timescale 1ns/100ps

`include "computer.sv"

module tb_computer;

    logic        clk, reset;
    logic        Exception_Flag;
    logic [15:0] writedata, dataaddr;
    logic        memwrite;

    // instantiate computer
    computer dut(
        .clk(clk), .reset(reset),
        .Exception_Flag(Exception_Flag),
        .writedata(writedata),
        .dataaddr(dataaddr),
        .memwrite(memwrite)
    );

    // ── clock ──
    initial clk = 0;
    always #5 clk = ~clk;

    // ── instruction name helper ──
    function string instr_name(input logic [15:0] instr);
        case (instr[15:12])
            4'h0: begin
                case (instr[3:0])
                    4'h0: instr_name = "AND ";
                    4'h1: instr_name = "OR  ";
                    4'h2: instr_name = "ADD ";
                    4'h3: instr_name = "NOR ";
                    4'h4: instr_name = "MFLO";
                    4'h5: instr_name = "MFHI";
                    4'h6: instr_name = "SUB ";
                    4'h7: instr_name = "SLT ";
                    4'h8: instr_name = "XOR ";
                    4'h9: instr_name = "SLL ";
                    4'ha: instr_name = "SRL ";
                    4'hb: instr_name = "MUL ";
                    default: instr_name = "R?? ";
                endcase
            end
            4'h1: instr_name = "ADDI";
            4'h2: instr_name = "LW  ";
            4'h3: instr_name = "SW  ";
            4'h4: instr_name = "BEQ ";
            4'h5: instr_name = "BNE ";
            4'h6: instr_name = "J   ";
            4'h7: instr_name = "JAL ";
            4'h8: instr_name = "LI  ";
            default: instr_name = "NOP ";
        endcase
    endfunction

    // ── header ──
    task print_header;
        $display("");
        $display("===================================================================================================================================================");
        $display("cyc |   pcF  | instrF | name | instrD | name |  aluoutM | wdataM | mw | R0   R1   R2   R3   R4   R5   R9   R12  | fwd stallF stallD flushE");
        $display("===================================================================================================================================================");
    endtask

    // ── row ──
    task print_row(input int cycle);
        $display(
            "%3d | %04h  | %04h   | %-4s | %04h   | %-4s | %04h     | %04h   |  %1b | %04h %04h %04h %04h %04h %04h %04h %04h | %1b%1b   %1b     %1b     %1b",
            cycle,
            dut.cpuUnit.pcF,
            dut.cpuUnit.instrF,
            instr_name(dut.cpuUnit.instrF),
            dut.cpuUnit.dp.instrD,
            instr_name(dut.cpuUnit.dp.instrD),
            dut.cpuUnit.dp.aluoutM,
            dut.cpuUnit.dp.writedataM,
            dut.memwrite,
            dut.cpuUnit.dp.rf.registers[0],
            dut.cpuUnit.dp.rf.registers[1],
            dut.cpuUnit.dp.rf.registers[2],
            dut.cpuUnit.dp.rf.registers[3],
            dut.cpuUnit.dp.rf.registers[4],
            dut.cpuUnit.dp.rf.registers[5],
            dut.cpuUnit.dp.rf.registers[9],
            dut.cpuUnit.dp.rf.registers[12],
            dut.cpuUnit.dp.forwardaD,
            dut.cpuUnit.dp.forwardbD,
            dut.cpuUnit.hu.stallF,
            dut.cpuUnit.hu.stallD,
            dut.cpuUnit.hu.flushE
        );
    endtask

    // ── main simulation ──
    initial begin
        $dumpfile("tb_computer.vcd");
        $dumpvars(0, tb_computer);

        Exception_Flag = 0;
        reset = 1;
        @(posedge clk);
        @(posedge clk);
        #1;
        reset = 0;

        print_header();

        for (int cycle = 1; cycle <= 40; cycle++) begin
            @(negedge clk);
            #1;
            print_row(cycle);
        end

        $display("===================================================================================================================================================");
        $finish;
    end

    // ── timeout ──
    initial begin
        #3000;
        $display("TIMEOUT");
        $finish;
    end

    // ── SW monitor ──
    // prints when a store instruction writes to memory
    always @(negedge clk) begin
        if (memwrite)
            $display("  --> SW: MEM[%04h] = %04h", dataaddr, writedata);
    end

endmodule

`endif
