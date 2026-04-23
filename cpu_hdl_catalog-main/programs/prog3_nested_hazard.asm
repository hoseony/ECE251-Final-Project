# prog3_nested_hazard.asm
# Nested procedure triggering a Load-Use Data Hazard via stack mapping

main:
    # Initialize stack pointer (using $sp natively)
    addi $sp, $zero, 60
    addi $s0, $zero, 10
    
    j stack_proc
    
return_from_stack:
    sw $zero, 252($zero)
    
stack_proc:
    # SW writes cleanly
    sw $s0, 0($sp)
    
    # LW pulls from memory
    lw $s1, 0($sp)
    
    # LOAD-USE HAZARD: 
    # Cannot forward from memory boundary fast enough!
    # Forces Pipeline inside hazard.sv to STALL natively for 1 clock cycle.
    add $s2, $s1, $s1
    
    j return_from_stack
    
halt:
    sw $zero, 252($zero)
