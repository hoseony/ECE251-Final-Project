# prog1_simple_nohazard.asm
# Linear sequence with NO overlapping data dependencies

main:
    addi $s0, $zero, 1
    addi $s1, $zero, 2
    addi $s2, $zero, 3
    
    # s4, s5, s6 operations are sufficiently spaced
    add $s4, $s0, $s1
    sub $s5, $s2, $s0
    add $s6, $s4, $s5
    
    # End of execution (Halt via Memory-Mapped I/O)
    sw $zero, 252($zero)
