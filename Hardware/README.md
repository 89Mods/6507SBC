# Hardware

Here are the KiCad projects for the computer! BOMs and Gerbers are in the respective 'production' folder of each KiCad project.

The 'expansion board' is a board that plugs directly into a header on the SBC, and adapts some of its I/O ports to two supported SPI peripherals, which can then be driven in software. One is a 25Qxx flash ROM for additional data storage (7KiB isn’t a lot), and the other a pixel LCD (ST7565), which forms the graphics output of the computer.

They can be found for cheap on AliExpress. I got [https://aliexpress.com/item/1005001621784395.html](this one).

However, in the absence of this, the SBC also has a header for a regular character LCD. If this is not required, components J5, RV1 and R19 can be omitted.
