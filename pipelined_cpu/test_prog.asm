# test_prog.asm
# Verify Pipelined CPU Data Hazards (Forwarding) and Control Hazards (Branch Flushing)

main:
    addi $t0, $zero, 5   # $t0 = 5
    addi $t1, $zero, 12  # $t1 = 12
    add  $t2, $t0, $t1   # $t2 = 17 (RAW EX hazard on $t0 and $t1)
    sub  $t3, $t2, $t0   # $t3 = 12 (RAW EX hazard on $t2)
    or   $t4, $t3, $t1   # $t4 = 12 (RAW EX hazard on $t3)
    sw   $t4, 84($zero)  # MEM hazard on $t4, stores 12 in datamem[84]
    lw   $t5, 84($zero)  # $t5 = 12
    add  $t6, $t5, $t1   # $t6 = 24 (Load-Use stall on $t5)
    beq  $t6, $t6, end   # Branch taken (Wait for $t6 to clear pipeline)
    addi $t0, $zero, 99  # Should be flushed
end:
    sw   $t6, 88($zero)  # Store 24 in datamem[88]
