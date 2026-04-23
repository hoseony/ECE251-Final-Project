#
# Fibonacci Sequence Generator (Iterative)
# This program calculates Fib(7) and stores the result in Data Memory.
#
.org 0                      # Memory begins at location 0x00000000

Main:
    addi $t0, $zero, 7      # $t0 = n (7)                    ; 20080007
    add  $t1, $zero, $zero  # $t1 = Fib(0) = 0               ; 00004820
    addi $t2, $zero, 1      # $t2 = Fib(1) = 1               ; 200a0001
Loop:
    beq  $t0, $zero, End    # if n == 0, break to End        ; 11000005
    add  $t3, $t1, $t2      # next_fib = Fib(n-2) + Fib(n-1) ; 012a5820
    add  $t1, $zero, $t2    # a = b                          ; 000a4820
    add  $t2, $zero, $t3    # b = next_fib                   ; 000b5020
    addi $t0, $t0, -1       # n = n - 1                      ; 2108ffff
    j    Loop               # jump to Loop                   ; 08000003
End:
    sw   $t1, 88($zero)     # mem[88] = Fib(7) = 13 (0x0D)   ; ac090058
