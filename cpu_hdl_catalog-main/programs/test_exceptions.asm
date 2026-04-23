# test_exceptions.asm
# Tests asynchronous interrupts triggering pipeline flushes and routing to the OS Handler

main:
    addi $s0, $zero, 0
loop:
    addi $s0, $s0, 1
    addi $s0, $s0, 1
    addi $s0, $s0, 1
    j loop

# OS Exception Handler (mapped by PC[7:2] ignoring high bits)
.org 0x180
handler:
    addi $k0, $zero, 999   # arbitrary math proving handler took over
    j handler
