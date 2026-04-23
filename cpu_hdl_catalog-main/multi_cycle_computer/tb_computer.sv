//////////////////////////////////////////////////////////////////////////////////
// The Cooper Union
// ECE 251 Spring 2023
// Engineer: Prof Rob Marano
// 
//     Create Date: 2023-02-07
//     Module Name: tb_computer
//     Description: Test bench for multi-cycle MIPS computer
//
//////////////////////////////////////////////////////////////////////////////////
`ifndef TB_COMPUTER
`define TB_COMPUTER

`timescale 1ns/100ps

`include "computer.sv"

module tb_computer;
  logic clk;
  logic reset;
  logic memwrite;
  logic [31:0] writedata;
  logic [31:0] adr;

  // instantiate the CPU as the device to be tested
  computer dut(clk, reset, writedata, adr, memwrite);

  // generate clock
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // initialize test
  initial begin
    $dumpfile("tb_computer.vcd");
    $dumpvars(0, dut);
    reset <= 1; # 22; reset <= 0;
  end

  // monitor what happens at negedge of clock transition
  always @(negedge clk) begin
    if(memwrite) begin
      // check for a specific success condition (e.g., writing 0x96 to address 84)
      if(adr === 84 & writedata === 32'h96) begin
          $display("Simulation Succeeded");
          $finish;
      end
    end
  end

  // timeout
  initial begin
    #5000;
    $display("Simulation Timeout");
    $finish;
  end

endmodule

`endif // TB_COMPUTER
