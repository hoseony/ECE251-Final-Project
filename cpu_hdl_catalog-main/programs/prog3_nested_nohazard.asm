# prog3_nested_nohazard.asm
# Nested procedure execution cleanly hopping scopes without RAW or control faults

main:
    addi $s0, $zero, 5
    
    # First jump layer (Outer Call)
    j outer_proc
    
return_from_outer:
    addi $s1, $s0, 5
    sw $zero, 252($zero)
    
outer_proc:
    addi $s2, $zero, 10
    # Second jump layer (Inner Call)
    j inner_proc
    
return_from_inner:
    add $s0, $s0, $s2
    j return_from_outer
    
inner_proc:
    addi $s3, $zero, 8
    add  $s2, $s2, $s3
    j return_from_inner
    
halt:
    sw $zero, 252($zero)
