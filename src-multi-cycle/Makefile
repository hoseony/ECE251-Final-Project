# =======================================================
# ECE251B Final Project - SystemVerilog Makefile
# =======================================================

IVERILOG = iverilog
VVP      = vvp

TARGET = tb_computer
WAVE   = tb_computer.vcd

SVFILES = \
	opcode.sv \
	computer.sv \
	cpu.sv \
	datapath.sv \
	controller.sv \
	mainDecoder.sv \
	aluDecoder.sv \
	alu.sv \
	adder.sv \
	dFF.sv \
	mux2.sv \
	mux4.sv \
	signExtend.sv \
	sl1.sv \
	registerFile.sv \
	mem.sv \
	fsm.sv \
	tb_computer.sv

all: run

$(TARGET): $(SVFILES)
	$(IVERILOG) -g2012 -o $(TARGET) $(SVFILES)

run: $(TARGET)
	$(VVP) $(TARGET)

wave: run
	open $(WAVE)

clean:
	rm -f $(TARGET) $(WAVE)

.PHONY: all run wave clean
