# result: MEM[0] = 14

main:
    li r9, 0        # base pointer = 0

    li r1, 5        # r1 = 7
    jal double      # call double

    sw r0, 0(r9)    # store return value

halt:
    j halt

double:
    add r1, r1      # r0 = r1 + r1
    jr r15          # return
