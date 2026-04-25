// =======================================================
// ECE251B - Computer Architecture
// Table Trace Testbench
// =======================================================

`ifndef TB_COMPUTER
`define TB_COMPUTER

`timescale 1ns/100ps

`include "computer.sv"

module tb_computer;

    logic clk;
    logic reset;

    logic [15:0] writeData;
    logic [15:0] dataAddress;
    logic        memWrite;

    computer dut(
        .clk(clk),
        .reset(reset),
        .writeData(writeData),
        .dataAddress(dataAddress),
        .memWrite(memWrite)
    );

    // ===================== Clock =====================
    initial clk = 0;
    always #5 clk = ~clk;

    // ===================== Instruction Name =====================
    function string instr_name(input logic [15:0] instr);
        begin
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
                        default: instr_name = "R???";
                    endcase
                end

                4'h1: instr_name = "ADDI";
                4'h2: instr_name = "LW  ";
                4'h3: instr_name = "SW  ";
                4'h4: instr_name = "BEQ ";
                4'h5: instr_name = "BNE ";
                4'h6: instr_name = "J   ";
                4'h7: instr_name = "JAL ";
                default: instr_name = "????";
            endcase
        end
    endfunction

    // ===================== Header =====================
    task print_header;
        begin
            $display("");
            $display("==================================================================================================================================================================================");
            $display("cyc | instr | name |   PC ->  PC' | op | a | b | f | srcA | srcB | alu  | rw | wr  | wb   | mw | addr | wdat | z | n | c | v | R0   R1   R2   R3   R4   R5   R9   R12  | MEM0");
            $display("==================================================================================================================================================================================");
        end
    endtask

    // ===================== Row =====================
    task print_row(
        input int          cycle,
        input logic [15:0] oldPC,
        input logic [15:0] oldInstr,
        input logic [15:0] oldSrcA,
        input logic [15:0] oldSrcB,
        input logic [15:0] oldAluOut,
        input logic        oldRegWrite,
        input logic [3:0]  oldWriteReg,
        input logic [15:0] oldResult,
        input logic        oldMemWrite,
        input logic [15:0] oldWriteData,
        input logic        oldZero,
        input logic        oldNegative,
        input logic        oldCarry,
        input logic        oldOverflow
    );
        begin
            $display(
                "%3d | %04h  | %-4s | %04h -> %04h |  %1h | %1h | %1h | %1h | %04h | %04h | %04h |  %1b | R%02d | %04h |  %1b | %04h | %04h | %1b | %1b | %1b | %1b | %04h %04h %04h %04h %04h %04h %04h %04h | %04h",
                cycle,
                oldInstr,
                instr_name(oldInstr),
                oldPC,
                dut.cpuUnit.pc,
                oldInstr[15:12],
                oldInstr[11:8],
                oldInstr[7:4],
                oldInstr[3:0],
                oldSrcA,
                oldSrcB,
                oldAluOut,
                oldRegWrite,
                oldWriteReg,
                oldResult,
                oldMemWrite,
                oldAluOut,
                oldWriteData,
                oldZero,
                oldNegative,
                oldCarry,
                oldOverflow,
                dut.cpuUnit.dp.rf.registers[0],
                dut.cpuUnit.dp.rf.registers[1],
                dut.cpuUnit.dp.rf.registers[2],
                dut.cpuUnit.dp.rf.registers[3],
                dut.cpuUnit.dp.rf.registers[4],
                dut.cpuUnit.dp.rf.registers[5],
                dut.cpuUnit.dp.rf.registers[9],
                dut.cpuUnit.dp.rf.registers[12],
                dut.dataMem.RAM[0]
            );
        end
    endtask

    // ===================== Main Simulation =====================
    initial begin
        int cycle;

        logic [15:0] oldPC;
        logic [15:0] oldInstr;

        logic [15:0] oldSrcA;
        logic [15:0] oldSrcB;
        logic [15:0] oldAluOut;

        logic        oldRegWrite;
        logic [3:0]  oldWriteReg;
        logic [15:0] oldResult;

        logic        oldMemWrite;
        logic [15:0] oldWriteData;

        logic        oldZero;
        logic        oldNegative;
        logic        oldCarry;
        logic        oldOverflow;

        $dumpfile("tb_computer.vcd");
        $dumpvars(0, tb_computer);

        reset = 1;

        @(posedge clk);
        @(posedge clk);

        #1;
        reset = 0;

        print_header();

        for (cycle = 1; cycle <= 12; cycle = cycle + 1) begin
            #1;

            // Snapshot BEFORE the instruction executes
            oldPC        = dut.cpuUnit.pc;
            oldInstr     = dut.cpuUnit.instr;

            oldSrcA      = dut.cpuUnit.dp.srcA;
            oldSrcB      = dut.cpuUnit.dp.srcB;
            oldAluOut    = dut.cpuUnit.dp.aluOut;

            oldRegWrite  = dut.cpuUnit.regWrite;
            oldWriteReg  = dut.cpuUnit.dp.writeReg;
            oldResult    = dut.cpuUnit.dp.result;

            oldMemWrite  = dut.cpuUnit.memWrite;
            oldWriteData = dut.cpuUnit.dp.writeData;

            oldZero      = dut.cpuUnit.dp.zero;
            oldNegative  = dut.cpuUnit.dp.negative;
            oldCarry     = dut.cpuUnit.dp.carry;
            oldOverflow  = dut.cpuUnit.dp.overflow;

            // Execute one instruction
            @(posedge clk);
            #1;

            print_row(
                cycle,
                oldPC,
                oldInstr,
                oldSrcA,
                oldSrcB,
                oldAluOut,
                oldRegWrite,
                oldWriteReg,
                oldResult,
                oldMemWrite,
                oldWriteData,
                oldZero,
                oldNegative,
                oldCarry,
                oldOverflow
            );
        end

        $display("=================================================================================================================================================================================");
        $finish;
    end

    // ===================== Timeout =====================
    initial begin
        #3000;
        $display("TIMEOUT");
        $finish;
    end

endmodule

`endif
