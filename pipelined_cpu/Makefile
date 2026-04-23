PROJECT_NAME=pipelined_cpu
SRCS=tb_computer.sv
VVPOPTS=-s tb_computer
ASM=test_prog

all: compile asm run

compile:
	/opt/homebrew/bin/iverilog -g2012 -o $(PROJECT_NAME).vvp $(SRCS)

run:
	/opt/homebrew/bin/vvp $(PROJECT_NAME).vvp > debug_output.txt

asm:
	python3 assembler.py $(ASM).asm $(ASM).exe
	# Adjust imem line if differing name
	# Assuming imem reads 'test_prog.exe'
	
clean:
	rm -f *.vvp *.vcd *.exe debug_output.txt
