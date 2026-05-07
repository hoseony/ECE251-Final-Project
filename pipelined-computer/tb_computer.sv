`ifndef TB_COMPUTER
`define TB_COMPUTER

`timescale 1ns/100ps

`include "computer.sv"

module tb_computer;

    logic        clk, reset;
    logic        Exception_Flag;
    logic [15:0] writedata, dataaddr;
    logic        memwrite;

    computer dut(
        .clk(clk),
        .reset(reset),
        .Exception_Flag(Exception_Flag),
        .writedata(writedata),
        .dataaddr(dataaddr),
        .memwrite(memwrite)
    );

    logic [15:0] R0, R1, R2, R9, R12, R15;

    assign R0  = dut.cpuUnit.dp.rf.registers[0];
    assign R1  = dut.cpuUnit.dp.rf.registers[1];
    assign R2  = dut.cpuUnit.dp.rf.registers[2];
    assign R9  = dut.cpuUnit.dp.rf.registers[9];
    assign R12 = dut.cpuUnit.dp.rf.registers[12];
    assign R15 = dut.cpuUnit.dp.rf.registers[15];

    initial clk = 0;
    always #5 clk = ~clk;

    function string instr_name(input logic [15:0] instr);

        if ($isunknown(instr)) begin
            instr_name = "----";
        end else begin
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
                        4'hc: instr_name = "PASSB";
                        4'hd: instr_name = "PASSA";
                        4'he: instr_name = "NOT ";
                        4'hf: instr_name = "NEG ";
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
                4'h9: instr_name = "ANDI";
                4'ha: instr_name = "ORI ";
                4'hb: instr_name = "XORI";
                4'hc: instr_name = "SLTI";
                4'hd: instr_name = "LUI ";
                4'he: instr_name = "JR  ";
                4'hf: instr_name = "NOP ";
                default: instr_name = "----";
            endcase
        end

    endfunction

    task print_header;
        $display("");
        $display("========================================================================================================================================================================================");
        $display("cyc | pcF  | instrF | name  | instrD | name  | aluoutM | wdataM | mw mr | ready mstall | R0   R1   R2   R3   R4   R5   R9   R12  R15  | fwdD | stallF stallD stallE stallM stallW flushE");
        $display("========================================================================================================================================================================================");
    endtask

    task print_row(input int cycle);
        $display(
            "%3d | %04h | %04h   | %-5s | %04h   | %-5s | %04h    | %04h   | %1b  %1b |   %1b      %1b   | %04h %04h %04h %04h %04h %04h %04h %04h %04h | %1b%1b   |   %1b      %1b      %1b      %1b      %1b      %1b",
            cycle,

            // Fetch / Decode
            dut.cpuUnit.pcF,
            dut.cpuUnit.instrF,
            instr_name(dut.cpuUnit.instrF),
            dut.cpuUnit.dp.instrD,
            instr_name(dut.cpuUnit.dp.instrD),

            // Memory stage
            dut.cpuUnit.dp.aluoutM,
            dut.cpuUnit.dp.writedataM,
            dut.memwrite,
            dut.memreadM,
            dut.dmem_ready,
            dut.mem_stall,

            // Registers
            dut.cpuUnit.dp.rf.registers[0],
            dut.cpuUnit.dp.rf.registers[1],
            dut.cpuUnit.dp.rf.registers[2],
            dut.cpuUnit.dp.rf.registers[3],
            dut.cpuUnit.dp.rf.registers[4],
            dut.cpuUnit.dp.rf.registers[5],
            dut.cpuUnit.dp.rf.registers[9],
            dut.cpuUnit.dp.rf.registers[12],
            dut.cpuUnit.dp.rf.registers[15],

            // Forwarding / stalls / flush
            dut.cpuUnit.dp.forwardaD,
            dut.cpuUnit.dp.forwardbD,
            dut.cpuUnit.hu.stallF,
            dut.cpuUnit.hu.stallD,
            dut.cpuUnit.hu.stallE,
            dut.cpuUnit.hu.stallM,
            dut.cpuUnit.hu.stallW,
            dut.cpuUnit.hu.flushE
        );
    endtask

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

        for (int cycle = 1; cycle <= 150; cycle++) begin
            @(negedge clk);
            #1;
            print_row(cycle);
        end

        $display("========================================================================================================================================================================================");
        $finish;
    end

    initial begin
        #10000;
        $display("TIMEOUT");
        $finish;
    end

    // This prints only when the delayed memory operation actually finishes.
    always @(negedge clk) begin
        if (dut.dmem_ready && dut.memwrite) begin
            $display("  --> SW COMMIT: MEM[%04h] = %04h", dataaddr, writedata);
        end
    end

    // Optional: print when a load completes too.
    always @(negedge clk) begin
        if (dut.dmem_ready && dut.memreadM) begin
            $display("  --> LW COMPLETE: MEM[%04h] -> %04h", dataaddr, dut.dmemUnit.readData);
        end
    end

endmodule

`endif
