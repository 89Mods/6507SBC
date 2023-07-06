.feature string_escapes
.feature org_per_seg
.feature c_comments

.segment "CODE"
NMI:
	rti
IRQ:
	rti
RESET:
	ldx #$FF
	txs
	ldx #0
print_loop:
	lda hello_text,X
	beq print_loop_end
	sta $FFFF
	inx
	jmp print_loop
print_loop_end:
	lda #'c'
	tay
	clc
	adc #1
	tax
	lda #'b'
	jsr test_subroutine
	sta $FFFF
	tya
	sta $FFFF
	txa
	sta $FFFF
	lda #13
	sta $FFFF
	lda #10
	sta $FFFF
	
	lda #'$'
	sta $FFFF
	lda #$69
	jsr print_hex
	lda #13
	sta $FFFF
	lda #10
	sta $FFFF
	
.byte $FF ; Invalid opcode to halt the simulator
loop:
	jmp loop
	
test_subroutine:
	pha
	lda #'a'
	sta $FFFF
	pla
	rts
	
print_hex:
	pha
	pha
	ror
	ror
	ror
	ror
	and #15
	tay
	lda hex_digits,Y
	sta $FFFF
	pla
	and #15
	tay
	lda hex_digits,Y
	sta $FFFF
	pla
	rts
	
hello_text:
.asciiz "Hi, I am 6507!\r\n"
.byte 0
hex_digits:
.asciiz "0123456789ABCDEF"
	
.byte 'E','O','F'

.segment "VECTORS"
.word NMI,RESET,IRQ
