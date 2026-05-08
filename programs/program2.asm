# result: MEM[0] = 13

main:
    li r9, 0        # base pointer = 0

    li r1, 6        # argument x = 6
    jal outer

    sw r0, 0(r9)    # store result

halt:
    j halt

outer:
    sw r15, 10(r9)  # save caller return address

    jal double      # r0 = double(r1)

    lw r15, 10(r9)  # restore caller return address
    addi r0, 1      # r0 = r0 + 1

    jr r15

double:
    add r1, r1      # r0 = r1 + r1
    jr r15
