PROJECT_NAME=pipelined_cpu
SRCS=tb_computer.sv
VVPOPTS=-s tb_computer
# Default assembly program if none is specified
ASM ?= test_prog
PROG_DIR = ../programs
TOOLS_DIR = ../tools

all: clean check_asm asm compile run

check_asm:
	@if [ ! -f $(PROG_DIR)/$(ASM).asm ]; then \
		echo "ERROR: Assembly file '$(PROG_DIR)/$(ASM).asm' not found!"; \
		echo "Available test files in $(PROG_DIR):"; \
		ls -1 $(PROG_DIR)/*.asm | sed "s|$(PROG_DIR)/||" | sed 's/\.asm//'; \
		exit 1; \
	fi

compile:
	iverilog -g2012 -o $(PROJECT_NAME).vvp $(SRCS)

run:
	vvp $(PROJECT_NAME).vvp +PROG=$(PROG_DIR)/$(ASM).exe > debug_output.txt
	@echo "\nSimulation complete! Check debug_output.txt for cycle-by-cycle logs."

asm:
	python3 $(TOOLS_DIR)/assembler.py $(PROG_DIR)/$(ASM).asm $(PROG_DIR)/$(ASM).exe

clean:
	rm -f *.vvp *.vcd debug_output.txt
