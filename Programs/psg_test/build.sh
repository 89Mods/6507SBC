set -e

./ca65 test.asm
./ld65 -C tholin_6507.cfg -o test.sfc test.o
java PadROM test.sfc
