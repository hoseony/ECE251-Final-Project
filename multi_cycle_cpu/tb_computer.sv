//////////////////////////////////////////////////////////////////////////////////
// The Cooper Union
// ECE 251 Spring 2023
// Engineer: Prof Rob Marano
// 
//     Create Date: 2023-02-07
//     Module Name: tb_computer
//     Description: Test bench for a single-cycle MIPS computer
//
// Revision: 1.0
//
//////////////////////////////////////////////////////////////////////////////////
`ifndef TB_COMPUTER
`define TB_COMPUTER

`timescale 1ns/100ps

`include "computer.sv"
`include "clock.sv"

module tb_computer;
  parameter n = 32; // # bits to represent the instruction / ALU operand / general purpose register (GPR)
  parameter m = 5;  // # bits to represent the address of the 2**m=32 GPRs in the CPU
  logic clk;
  logic clk_enable;
  logic reset;
  logic memwrite;
  logic [31:0] writedata;
  logic [31:0] dataadr;

  logic firstTest, secondTest;
  integer cycle_count;

  // instantiate the CPU as the device to be tested
  computer dut(clk, reset, writedata, dataadr, memwrite);
  // generate clock to sequence tests
  // always
  //   begin
  //     clk <= 1; # 5; clk <= 0; # 5;
  //   end

  // instantiate the clock
  clock dut1(.ENABLE(clk_enable), .CLOCK(clk));


  initial begin
    firstTest = 1'b0;
    secondTest = 1'b0;
    cycle_count = 0;
    $dumpfile("tb_computer.vcd");
    $dumpvars(0,dut1,clk,reset,writedata,dataadr,memwrite);
    $monitor("t=%t\t0x%7h\t%7d\t%8d",$realtime,writedata,dataadr,memwrite);
    // $dumpvars(0,clk,a,b,ctrl,result,zero,negative,carryOut,overflow);
    // $display("Ctl Z  N  O  C  A                    B                    ALUresult");
    // $monitor("%3b %b  %b  %b  %b  %8b (0x%2h;%3d)  %8b (0x%2h;%3d)  %8b (0x%2h;%3d)",ctrl,zero,negative,overflow,carryOut,a,a,a,b,b,b,result,result,result);
  end

  // initialize test
  initial begin
    #0 clk_enable <= 0; #50 reset <= 1; # 50; reset <= 0; #50 clk_enable <= 1;
    #30000 $finish;
  end

  // monitor what happens at posedge of clock transition
  always @(posedge clk)
  begin
      cycle_count = cycle_count + 1;
      $display("+");
      $display("\t+cycle_count = %d", cycle_count);
      $display("\t+state = %d",dut.mips.c.md.state);
      $display("\t+instr = 0x%8h",dut.mips.dp.instr);
      $display("\t+op = 0b%6b",dut.mips.c.op);
      $display("\t+controls = 0b%15b",dut.mips.c.md.controls);
      $display("\t+funct = 0b%6b",dut.mips.c.ad.funct);
      $display("\t+aluop = 0b%2b",dut.mips.c.ad.aluop);
      $display("\t+alucontrol = 0b%3b",dut.mips.c.ad.alucontrol);
      $display("\t+alu result = 0x%8h",dut.mips.dp.alu.result);
      $display("\t+$t0 = 0x%4h",dut.mips.dp.rf.rf[8]);
      $display("\t+$t1 = 0x%4h",dut.mips.dp.rf.rf[9]);
      $display("\t+$t2 = 0x%4h",dut.mips.dp.rf.rf[10]);
      $display("\t+regfile -- wa3 = %d",dut.mips.dp.rf.wa3);
      $display("\t+regfile -- wd3 = %d",dut.mips.dp.rf.wd3);
      $display("\t+RAM[%4d] = %4d",dut.mem.addr,dut.mem.rd);
      $display("writedata\tdataadr\tmemwrite");
  end

  // run program
  // monitor what happens at negedge of clock transition
  always @(negedge clk) begin
    $display("-");
    // Omitting duplicate lines to save space
    $display("writedata\tdataadr\tmemwrite");
  end

  always @(negedge clk, posedge clk) begin
    // check results
    if (dut.mem.RAM[21] === 32'h96)
      begin
        $display("Successfully wrote mult_prog result 0x%4h at RAM[%3d]",84,32'h0096);
        firstTest = 1'b1;
      end
    if (dut.mem.RAM[22] === 32'h0D)
      begin
        $display("Successfully wrote fib_prog result Fib(7)=0x0D at RAM[%3d]",88);
        firstTest = 1'b1;
      end
    if(memwrite) begin
      if(dataadr === 84 & writedata === 32'h96)
      begin
        $display("MULT_PROG SUCCESS: Wrote 0x%4h at RAM[%3d] in %d cycles",writedata,dataadr,cycle_count);
        firstTest = 1'b1;
      end
      if(dataadr === 88 & writedata === 32'h0d)
      begin
        $display("FIB_PROG SUCCESS: Wrote Fib(7)=0x%4h at RAM[%3d] in %d cycles",writedata,dataadr,cycle_count);
        firstTest = 1'b1;
      end
    end
    if (firstTest === 1'b1)
    begin
        $display("Program successfully completed");
        $finish;
    end
  end

endmodule

`endif // TB_COMPUTER