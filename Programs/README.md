# Programs

Here are various programs to test the computer’s hardware, and stress the CPU and Memory (mandelbrot renderer). Due to the memory map of the system, the ROM binaries must be padded with 1024 bytes of 0s at the beginning. The PadROM script written in Java takes care of this.

Every program is contained in its own directory, which also contains a bash script to automatically run all the commands to build the program. cc65 is required to assemble the programs.

<table>
    <tr>
        <th>Name</th>
        <th>Description</th>
    </tr>
    <tr>
        <td>board_test</td>
        <td>Just blinks some LEDs, makes beepboops and puts text on the character LCD.</td>
    </tr>
    <tr>
        <td>mandel</td>
        <td>Mandelbrot set renderer. Makes use of the pixel LCD.</td>
    </tr>
    <tr>
        <td>psg_test</td>
        <td>Tests the sound output by playing some tunes.</td>
    </tr>
    <tr>
        <td>spi_lcd_test</td>
        <td>Copies a bitmap image onto the SPI LCD for testing purposes.</td>
    </tr>
    <tr>
        <td>spi_rom_test</td>
        <td>Plays a VGM file from the SPI ROM. Code is a bit of a mess due to containing dummy subroutines to make the timing of the notes work out.</td>
    </tr>
</table>
