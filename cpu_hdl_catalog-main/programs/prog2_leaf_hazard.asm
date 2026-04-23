# prog2_leaf_hazard.asm
# Leaf procedure triggering a Branch Hazard (Control Hazard) on BEQ

main:
    addi $s0, $zero, 1
    addi $s1, $zero, 1
    
    # BEQ causes a control hazard natively since IF/ID must flush predictions
    beq $s0, $s1, leaf_proc
    
    # This should be skipped/flushed dynamically!
    addi $s2, $zero, 999 
    
return_from_leaf:
    j halt
    
leaf_proc:
    add $s2, $s0, $s1
    j return_from_leaf
    
halt:
    # End of execution (Halt via Memory-Mapped I/O)
    sw $zero, 252($zero)
