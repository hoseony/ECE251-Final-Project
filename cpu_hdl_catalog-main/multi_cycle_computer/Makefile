#
# Makefile for Multi-cycle MIPS
#
COMPONENT = computer
SRC = tb_computer.sv
TBOUTPUT = tb_computer.vcd

COMPILER = iverilog
SIMULATOR = vvp
VIEWER = gtkwave

COFLAGS = -g2012
SFLAGS = -M .
SOUTPUT = -lxt2

.PHONY: compile simulate display clean

compile : $(SRC)
	$(COMPILER) $(COFLAGS) -o $(COMPONENT).vvp $(SRC)

simulate: $(COMPONENT).vvp
	$(SIMULATOR) $(SFLAGS) $(COMPONENT).vvp $(SOUTPUT)

display: $(TBOUTPUT)
	$(VIEWER) $(TBOUTPUT) &

clean:
	/bin/rm -f $(COMPONENT).vvp *.vcd a.out compiler.out
