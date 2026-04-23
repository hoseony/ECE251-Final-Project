# prog2_leaf_nohazard.asm
# Leaf procedure execution without hazards using explicit absolute jumps

main:
    addi $s0, $zero, 10
    
    # No hazard bubble needed, immediate jump to simulate subroutine call
    j leaf_proc
    
return_from_leaf:
    addi $s1, $s0, 5
    j halt
    
leaf_proc:
    # Independent calculation (no RAW hazard against $s1)
    addi $s2, $zero, 20
    add  $s0, $s0, $s2
    j return_from_leaf
    
halt:
    sw $zero, 252($zero)
