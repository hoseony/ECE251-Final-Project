// =======================================================
// ECE251B - Computer Architecture
// Multicycle Computer Table Trace Testbench
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
                4'h8: instr_name = "LI  ";   // FIX
                default: instr_name = "????";
            endcase
        end
    endfunction

    // ===================== Header =====================
    task print_header;
        begin
            $display("");
            $display("================================================================================================================================================================================================");
            $display("cyc | state | instr | name |   PC ->  PC' | op | a | b | f | srcA | srcB | alu  | alureg | rw | wr  | wb   | mw | addr | wdat | z | n | c | v | R0   R1   R2   R3   R4   R5   R9   R12  | MEM0");
            $display("================================================================================================================================================================================================");
        end
    endtask

    // ===================== Row =====================
    task print_row(
        input int          cycle,
        input logic [15:0] pcBefore,
        input logic [15:0] instr,
        input logic [15:0] srcA,
        input logic [15:0] srcB,
        input logic [15:0] aluOut,
        input logic [15:0] aluRegOut,
        input logic        regWrite,
        input logic [3:0]  writeReg,
        input logic [15:0] result,
        input logic        memWrite,
        input logic [15:0] memAddress,
        input logic [15:0] writeData,
        input logic        zero,
        input logic        negative,
        input logic        carry,
        input logic        overflow
    );
        begin
            $display(
                "%3d |  %02h   | %04h  | %-4s | %04h -> %04h |  %1h | %1h | %1h | %1h | %04h | %04h | %04h |  %04h  |  %1b | R%02d | %04h |  %1b | %04h | %04h | %1b | %1b | %1b | %1b | %04h %04h %04h %04h %04h %04h %04h %04h | %04h",
                cycle,
                dut.cpuUnit.ctrl.fs.state,

                instr,
                instr_name(instr),
                pcBefore,
                dut.cpuUnit.pc,

                instr[15:12],
                instr[11:8],
                instr[7:4],
                instr[3:0],

                srcA,
                srcB,
                aluOut,
                aluRegOut,

                regWrite,
                writeReg,
                result,

                memWrite,
                memAddress,
                writeData,

                zero,
                negative,
                carry,
                overflow,

                dut.cpuUnit.dp.rf.registers[0],
                dut.cpuUnit.dp.rf.registers[1],
                dut.cpuUnit.dp.rf.registers[2],
                dut.cpuUnit.dp.rf.registers[3],
                dut.cpuUnit.dp.rf.registers[4],
                dut.cpuUnit.dp.rf.registers[5],
                dut.cpuUnit.dp.rf.registers[9],
                dut.cpuUnit.dp.rf.registers[12],

                dut.memory.RAM[0]
            );
        end
    endtask

    // ===================== Main Simulation =====================
    initial begin
        int cycle;

        logic [15:0] pcBefore;
        logic [15:0] instr;

        logic [15:0] srcA;
        logic [15:0] srcB;
        logic [15:0] aluOut;
        logic [15:0] aluRegOut;

        logic        regWrite;
        logic [3:0]  writeReg;
        logic [15:0] result;

        logic        memWriteSnap;
        logic [15:0] memAddress;
        logic [15:0] writeDataSnap;

        logic        zero;
        logic        negative;
        logic        carry;
        logic        overflow;

        $dumpfile("tb_computer.vcd");
        $dumpvars(0, tb_computer);

        reset = 1;

        @(posedge clk);
        @(posedge clk);

        #1;
        reset = 0;

        print_header();

        // Multicycle CPU: one row = one FSM cycle, not one full instruction.
        for (cycle = 1; cycle <= 40; cycle = cycle + 1) begin
            #1;

            pcBefore     = dut.cpuUnit.pc;
            instr        = dut.cpuUnit.dp.instrOut;

            srcA         = dut.cpuUnit.dp.srcA;
            srcB         = dut.cpuUnit.dp.srcB;
            aluOut       = dut.cpuUnit.dp.aluOut;
            aluRegOut    = dut.cpuUnit.dp.aluRegOut;

            regWrite     = dut.cpuUnit.regWrite;
            writeReg     = dut.cpuUnit.dp.writeReg;
            result       = dut.cpuUnit.dp.result;

            memWriteSnap = dut.cpuUnit.memWrite;
            memAddress   = dut.cpuUnit.memAddress;
            writeDataSnap = dut.cpuUnit.dp.writeData;

            zero         = dut.cpuUnit.dp.zero;
            negative     = dut.cpuUnit.dp.negative;
            carry        = dut.cpuUnit.dp.carry;
            overflow     = dut.cpuUnit.dp.overflow;

            @(posedge clk);
            #1;

            print_row(
                cycle,
                pcBefore,
                instr,
                srcA,
                srcB,
                aluOut,
                aluRegOut,
                regWrite,
                writeReg,
                result,
                memWriteSnap,
                memAddress,
                writeDataSnap,
                zero,
                negative,
                carry,
                overflow
            );
        end

        $display("====================================================================================================================================================================================================");
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
