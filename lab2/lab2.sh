riscv64-unknown-elf-gcc -Ofast -o unsignedHighest.o unsignedHighest.c
spike pk unsignedHighest.o
riscv64-unknown-elf-gcc -Ofast -o signedHighest.o signedHighest.c
spike pk signedHighest.o

