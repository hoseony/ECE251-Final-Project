# =======================================================
# ECE251B - Computer Architecture
# Prof. Rob Marano
# Author: Hoseon Yu & Evan Dong
#
# Programs Makefile
# =======================================================

ASM     = python3 ../tools/assembler.py
asm     ?= test.asm      # default input
out     ?= program       # default output

# ── default: assemble ──
all:
	$(ASM) $(asm) $(out)

# ── assemble and run simulation ──
run: all
	cd ../hy-pipe && make run

# ── list available programs ──
list:
	@echo "Available .asm files:"
	@ls *.asm

# ── clean ──
clean:
	rm -f program

.PHONY: all run list clean
