# result: MEM[0] = 10

main:
    li r9, 0        # base pointer = 0

    li r1, 5
    li r2, 3

    add r1, r2      # r0 = r1 + r2 = 8
    addi r0, 2      # r0 = r0 + 2 = 10

    sw r0, 0(r9)    # MEM[0] = 10

halt:
    j halt
