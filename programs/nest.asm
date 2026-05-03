main:
    li r0, 0
    li r1, 5
    li r2, 3
    add r1, r2
    j leaf

leaf:
    addi r0, 3
    add r1, r2
    j halt

halt:
    j halt
