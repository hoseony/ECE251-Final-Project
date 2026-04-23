# prog1_simple_hazard.asm
# RAW Hazard (Read-After-Write) resolved by execution forwarding

main:
    addi $s0, $zero, 1
    
    # Data hazard immediately follows! 
    # $s0 is written by ADDI (still in pipeline)
    # Below ADD wants to read $s0 instantly.
    add $s1, $s0, $s0
    
    # Chain dependency on $s1
    add $s2, $s1, $s1

    # adding more to extend the pipeline
    addi $s3, $zero, 1
    addi $s3, $zero, 1
    addi $s3, $zero, 1
    addi $s3, $zero, 1
    addi $s3, $zero, 1
    addi $s3, $zero, 1
    addi $s3, $zero, 1
    addi $s3, $zero, 1
    addi $s3, $zero, 1
    addi $s3, $zero, 1
    addi $s3, $zero, 1
    addi $s3, $zero, 1
    addi $s3, $zero, 1
    
    # End of execution (Halt via Memory-Mapped I/O)
    sw $zero, 252($zero)
