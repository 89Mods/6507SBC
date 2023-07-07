# 6507SBC

A 6507-based single-board computer with 128 bytes RAM, 7KiB ROM, I/O, graphics and sound. As an added challenge, it was built with the requirement to not contain any IC larger than DIP-28.

`Hardware` contains the KiCad project files for the SBC itself, as well as the adapter board for the supported SPI peripherals.

`Programs` are programs written to test various features of the SBC.

`Verilog` contains a basic Verilog implementation of the 6507, and the pixel LCD peripheral. Used during software development when ROM swapping became too tedious. Doesn’t implement undocumented instructions or decimal mode.
