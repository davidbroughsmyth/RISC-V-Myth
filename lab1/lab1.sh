gcc -o sum1toN sum1toN.c
./sum1toN
riscv64-unknown-elf-gcc -O1  -o rv64_sum1toN-O1.o sum1toN.c
riscv64-unknown-elf-objdump -d  rv64_sum1toN-O1.o > rv64_sum1toN-O1_dis.txt
riscv64-unknown-elf-gcc -Ofast  -o rv64_sum1toN-Ofast.o sum1toN.c
riscv64-unknown-elf-objdump -d  rv64_sum1toN-Ofast.o > rv64_sum1toN-Ofast_dis.txt
time spike pk rv64_sum1toN-O1.o
time spike pk rv64_sum1toN-Ofast.o
