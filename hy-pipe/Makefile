# compiler and flags
IVERILOG = iverilog
VVP      = vvp
FLAGS    = -g2012

# top level testbench
TOP      = tb_computer.sv
SIM_BIN  = sim
VCD      = tb_computer.vcd

all: $(SIM_BIN)

$(SIM_BIN): $(TOP)
	$(IVERILOG) $(FLAGS) -o $(SIM_BIN) $(TOP)

run: $(SIM_BIN)
	$(VVP) $(SIM_BIN)

clean:
	rm -f $(SIM_BIN) $(VCD)

.PHONY: all run clean
