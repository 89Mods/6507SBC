set -e

./ca65 mandel.asm
./ld65 -C tholin_6507.cfg -o mandel.sfc mandel.o
java PadROM mandel.sfc
