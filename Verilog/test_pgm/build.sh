set -e

../cc65/bin/ca65 test.asm
../cc65/bin/ld65 -C tholin_6507.cfg -o test.sfc test.o
java PadROM test.sfc
java ToHex rom.bin
