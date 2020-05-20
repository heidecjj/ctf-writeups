all: a.hex

a.o: a.asm
	riscv64-linux-gnu-as -march=rv64ic -fpic -o a.o a.asm
a: a.o
	riscv64-linux-gnu-ld -o a a.o
a.hex: a
	riscv64-linux-gnu-objcopy -O binary -j .text a a.tmp
	xxd -c 1100 -ps a.tmp > a.hex

