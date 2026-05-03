main:
    li r9, 0x40      // stack pointer starts at byte address 0x40
    li r1, 4         // compute factorial(4)
    jal fact
    j halt

fact:
    // if n == 0, return 1
    li r0, 0
    beq r1, base

    // save return address and n
    sw r15, 0(r9)
    sw r1, 2(r9)
    addi r9, 4

    // fact(n - 1)
    addi r1, -1
    jal fact

    // restore stack
    addi r9, -4
    lw r1, 2(r9)
    lw r15, 0(r9)

    // r0 = fact(n-1), now multiply by n
    mul r0, r1       // HiLo = R0 * R1
    mflo             // R0 = low result

    jr r15

base:
    li r0, 1
    jr r15

halt:
    j halt
