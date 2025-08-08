riscv64-unknown-elf-gcc -Ofast -o 1to9_custom.o 1to9_custom.c load.S
spike pk 1to9_custom.o
