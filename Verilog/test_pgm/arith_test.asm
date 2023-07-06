.feature string_escapes
.feature org_per_seg
.feature c_comments

mem_start = $80
min00 = mem_start
min01 = mem_start+1
min02 = mem_start+2
min03 = mem_start+3
min10 = mem_start+4
min11 = mem_start+5
min12 = mem_start+6
min13 = mem_start+7
mres0 = mem_start+8
mres1 = mem_start+9
mres2 = mem_start+10
mres3 = mem_start+11
mres4 = mem_start+12
mres5 = mem_start+13
mres6 = mem_start+14
mres7 = mem_start+15
mtemp0 = mem_start+16
mtemp1 = mem_start+17
mtemp2 = mem_start+18
mtemp3 = mem_start+19
mtemp4 = mem_start+20
mtemp5 = mem_start+21
mtemp6 = mem_start+22
rem0 = mem_start+23
rem1 = mem_start+24
rem2 = mem_start+25
rem3 = mem_start+26

temp0 = mem_start+27

.segment "CODE"
NMI:
	rti
IRQ:
	nop
	lda #'C'
	sta $FFFF
	lda #'h'
	sta $FFFF
	lda #'i'
	sta $FFFF
	lda #'r'
	sta $FFFF
	lda #'p'
	sta $FFFF
	lda #'!'
	sta $FFFF
	lda #10
	sta $FFFF
	lda #13
	sta $FFFF
	nop
	rti
RESET:
	ldx #$FF
	txs
	brk
	
	ldx #0
test_loop_1:
	lda m_ins_8x8,X
	cmp #255
	beq test_loop_1_end
	inx
	jsr print_hex
	sta min00
	lda #'*'
	sta $FFFF
	lda m_ins_8x8,X
	jsr print_hex
	sta min10
	lda #'='
	sta $FFFF
	jsr mul_8x8
	lda mres1
	jsr print_hex
	lda mres0
	jsr print_hex
	lda #10
	sta $FFFF
	lda #13
	sta $FFFF
	inx
	jmp test_loop_1
test_loop_1_end:
	lda #10
	sta $FFFF
	lda #13
	sta $FFFF
	ldx #0
test_loop_2:
	lda div_ins_16x16,X
	sta min01
	cmp #255
	beq test_loop_2_end
	jsr print_hex
	inx
	lda div_ins_16x16,X
	jsr print_hex
	sta min00
	lda #'/'
	inx
	sta $FFFF
	lda div_ins_16x16,X
	jsr print_hex
	sta min11
	inx
	lda div_ins_16x16,X
	inx
	jsr print_hex
	sta min10
	lda #'='
	sta $FFFF
	jsr div_16x16
	lda mres1
	jsr print_hex
	lda mres0
	jsr print_hex
	lda #' '
	sta $FFFF
	lda #'R'
	sta $FFFF
	lda #':'
	sta $FFFF
	lda #' '
	sta $FFFF
	lda rem1
	jsr print_hex
	lda rem0
	jsr print_hex
	
	lda #10
	sta $FFFF
	lda #13
	sta $FFFF
	jmp test_loop_2
	
test_loop_2_end:
	lda #10
	sta $FFFF
	lda #13
	sta $FFFF
	
	ldx #0
test_loop_3:
	lda mul_ins_32x32,X
	sta min03
	cmp #255
	beq test_loop_3_end
	jsr print_hex
	inx
	lda mul_ins_32x32,X
	sta min02
	jsr print_hex
	inx
	lda mul_ins_32x32,X
	sta min01
	jsr print_hex
	inx
	lda mul_ins_32x32,X
	sta min00
	jsr print_hex
	inx
	lda #'*'
	sta $FFFF
	ldy #4
copy_loop_0:
	dey
	lda mul_ins_32x32,X
	inx
	sta min10,Y
	jsr print_hex
	tya
	bne copy_loop_0
	lda #'='
	sta $FFFF
	jsr mul_32x32
	ldy #8
print_loop_1:
	dey
	lda mres0,Y
	jsr print_hex
	tya
	bne print_loop_1
	lda #10
	sta $FFFF
	lda #13
	sta $FFFF
	
	jmp test_loop_3
	
test_loop_3_end:
	lda #10
	sta $FFFF
	lda #13
	sta $FFFF
	
	ldx #0
test_loop_4:
	lda div_ins_32x32,X
	sta min03
	cmp #255
	beq test_loop_4_end
	jsr print_hex
	inx
	lda div_ins_32x32,X
	sta min02
	jsr print_hex
	inx
	lda div_ins_32x32,X
	sta min01
	jsr print_hex
	inx
	lda div_ins_32x32,X
	sta min00
	jsr print_hex
	inx
	lda #'/'
	sta $FFFF
	ldy #4
copy_loop_1:
	dey
	lda div_ins_32x32,X
	inx
	sta min10,Y
	jsr print_hex
	tya
	bne copy_loop_1
	lda #'='
	sta $FFFF
	jsr div_32x32
	ldy #4
print_loop_2:
	dey
	lda mres0,Y
	jsr print_hex
	tya
	bne print_loop_2
	
	lda #' '
	sta $FFFF
	lda #'R'
	sta $FFFF
	lda #':'
	sta $FFFF
	lda #' '
	sta $FFFF
	
	ldy #4
print_loop_3:
	dey
	lda rem0,Y
	jsr print_hex
	tya
	bne print_loop_3
	
	lda #10
	sta $FFFF
	lda #13
	sta $FFFF
	jmp test_loop_4
	
test_loop_4_end:
	lda #10
	sta $FFFF
	lda #13
	sta $FFFF
	
	ldx #0
test_loop_5:
	lda print_num_ins,X
	sta min00
	inx
	cmp #255
	beq test_loop_5_end
	lda print_num_ins,X
	sta min01
	inx
	lda print_num_ins,X
	sta min02
	inx
	lda print_num_ins,X
	sta min03
	inx
	jsr print_num
	lda #10
	sta $FFFF
	lda #13
	sta $FFFF
	jmp test_loop_5
	
test_loop_5_end:
	lda #10
	sta $FFFF
	lda #13
	sta $FFFF
	
	lda #$3F
	sta min03
	jsr print_hex
	lda #'.'
	sta $FFFF
	lda #$27
	sta min02
	jsr print_hex
	lda #$00
	sta min01
	sta min00
	jsr print_hex
	jsr print_hex
	lda #'*'
 	sta $FFFF
	lda #$00
	sta min13
	jsr print_hex
	lda #'.'
	sta $FFFF
	lda #$71
	sta min12
	jsr print_hex
	lda #$01
	sta min11
	jsr print_hex
	lda #$00
	sta min10
	jsr print_hex
	lda #'='
	sta $FFFF
	jsr mul_fixed
	
	lda mres3
	pha
	lda mres2
	pha
	lda mres1
	pha
	lda mres0
	pha
	
	lda mres3
	jsr print_hex
	lda #'.'
	sta $FFFF
	lda mres2
	jsr print_hex
	lda mres1
	jsr print_hex
	lda mres0
	jsr print_hex
	lda #10
	sta $FFFF
	lda #13
	sta $FFFF
	
	lda #$3F
	sta min03
	lda #$27
	sta min02
	lda #$00
	sta min01
	sta min00
	jsr print_fixed
	lda #'*'
	sta $FFFF
	lda #$00
	sta min03
	lda #$71
	sta min02
	lda #$01
	sta min01
	lda #$00
	sta min00
	jsr print_fixed
	lda #'='
	sta $FFFF
	pla
	sta min00
	pla
	sta min01
	pla
	sta min02
	pla
	sta min03
	jsr print_fixed
	lda #10
	sta $FFFF
	lda #13
	sta $FFFF
	
	lda #$29
	sta min03
	lda #$C6
	sta min02
	lda #$88
	sta min01
	sta min00
	jsr print_fixed
	lda #'/'
	sta $FFFF
	lda #$01
	sta min03
	lda #$3A
	sta min02
	lda #$1D
	sta min01
	lda #$0F
	sta min00
	jsr print_fixed
	lda #'='
	sta $FFFF
	lda #$01
	sta min13
	lda #$3A
	sta min12
	lda #$1D
	sta min11
	lda #$0F
	sta min10
	lda #$29
	sta min03
	lda #$C6
	sta min02
	lda #$88
	sta min01
	sta min00
	jsr div_fixed
	lda mres0
	sta min00
	lda mres1
	sta min01
	lda mres2
	sta min02
	lda mres3
	sta min03
	jsr print_fixed
	lda #10
	sta $FFFF
	lda #13
	sta $FFFF
	
	lda #10
	sta $FFFF
	lda #13
	sta $FFFF
	
.byte $FF ; Invalid opcode to halt the simulator
loop:
	jmp loop

mul_8x8:
	lda #0
	sta mres0
	sta mres1
	sta mtemp0
mul_8x8_loop:
	lsr min00
	bcc mul_8x8_no_carry
	clc
	lda mres0
	adc min10
	sta mres0
	lda mres1
	adc mtemp0
	sta mres1
mul_8x8_no_carry:
	asl min10
	rol mtemp0
	lda min00
	bne mul_8x8_loop
	rts
	
mul_32x32:
	lda #0
	sta mres0
	sta mres1
	sta mres2
	sta mres3
	sta mres4
	sta mres5
	sta mres6
	sta mres7
	tya
	pha
	txa
	pha
	ldy #0
	ldx #0
mul_32x32_loop:
	tya
	lda min00,Y
	iny
	sta mtemp0
	jsr mul_8x32
	
	clc
	lda mtemp2
	adc mres0,X
	sta mres0,X
	lda mtemp3
	adc mres1,X
	sta mres1,X
	lda mtemp4
	adc mres2,X
	sta mres2,X
	lda mtemp5
	adc mres3,X
	sta mres3,X
	lda mtemp6
	adc mres4,X
	sta mres4,X
	inx
	
	tya
	cmp #4
	bne mul_32x32_loop
	
	pla
	tax
	pla
	tay
	
	rts
	
mul_8x32:
	lda #0
	sta mtemp1
	sta mtemp2
	sta mtemp3
	sta mtemp4
	sta mtemp5
	sta mtemp6
	lda mtemp0
	bne mul_8x32_nonzero
	rts
mul_8x32_nonzero:
	lda min13
	pha
	lda min12
	pha
	lda min11
	pha
	lda min10
	pha
mul_8x32_loop:
	lsr mtemp0
	bcc mul_8x32_no_carry
	clc
	lda mtemp2
	adc min10
	sta mtemp2
	lda mtemp3
	adc min11
	sta mtemp3
	lda mtemp4
	adc min12
	sta mtemp4
	lda mtemp5
	adc min13
	sta mtemp5
	lda mtemp6
	adc mtemp1
	sta mtemp6
mul_8x32_no_carry:
	asl min10
	rol min11
	rol min12
	rol min13
	rol mtemp1
	lda mtemp0
	bne mul_8x32_loop
mul_8x32_end:
	pla
	sta min10
	pla
	sta min11
	pla
	sta min12
	pla
	sta min13
	rts

mul_fixed:
	lda #0
	sta temp0
	txa
	pha
	lda min03
	bpl mul_fixed_not_neg_1
	
	sec
	ldx #0
mul_fixed_inv_loop_0:
	lda min00,X
	eor #255
	adc #0
	sta min00,X
	inx
	txa
	cmp #4
	bne mul_fixed_inv_loop_0
	lda #1
	eor temp0
	sta temp0
	
mul_fixed_not_neg_1:
	lda min13
	bpl mul_fixed_not_neg_2
	
	sec
	ldx #0
mul_fixed_inv_loop_1:
	lda min10,X
	eor #255
	adc #0
	sta min10,X
	inx
	txa
	cmp #4
	bne mul_fixed_inv_loop_1
	lda #1
	eor temp0
	sta temp0
	
mul_fixed_not_neg_2:
	pla
	tax
	
	lda temp0
	pha
	jsr mul_32x32
	
	lda mres3
	sta mres0
	lda mres4
	sta mres1
	lda mres5
	sta mres2
	lda mres6
	sta mres3
	
	pla
	beq mul_fixed_not_neg_3
	
	txa
	sta temp0
	sec
	ldx #0
mul_fixed_inv_loop_2:
	lda mres0,X
	eor #255
	adc #0
	sta mres0,X
	inx
	txa
	cmp #4
	bne mul_fixed_inv_loop_2
	lda temp0
	tax
	
mul_fixed_not_neg_3:
	lda #0
	sta mres7
	sta mres6
	sta mres5
	sta mres4
	rts

div_16x16:
	lda #0
	sta mres0
	sta mres1
	sta mtemp0
	sta mtemp1
	lda #16
	sta mtemp2
div_16x16_loop:
	asl mres0
	rol mres1
	asl min00
	rol min01
	rol mtemp0
	rol mtemp1
	sec
	lda mtemp0
	sbc min10
	lda mtemp1
	sbc min11
	bcc div_16x16_continue
	sec
	lda mtemp0
	sbc min10
	sta mtemp0
	lda mtemp1
	sbc min11
	sta mtemp1
	inc mres0
div_16x16_continue:
	dec mtemp2
	bne div_16x16_loop
	lda mtemp0
	sta rem0
	lda mtemp1
	sta rem1
	rts

div_32x32:
	lda #0
	sta mres0
	sta mres1
	sta mres2
	sta mres3
	sta mtemp0
	sta mtemp1
	sta mtemp2
	sta mtemp3
	lda #32
	sta mtemp4
div_32x32_loop:
	asl mres0
	rol mres1
	rol mres2
	rol mres3
	
	asl min00
	rol min01
	rol min02
	rol min03
	rol mtemp0
	rol mtemp1
	rol mtemp2
	rol mtemp3
	
	sec
	lda mtemp0
	sbc min10
	lda mtemp1
	sbc min11
	lda mtemp2
	sbc min12
	lda mtemp3
	sbc min13
	bcc div_32x32_continue
	
	sec
	lda mtemp0
	sbc min10
	sta mtemp0
	lda mtemp1
	sbc min11
	sta mtemp1
	lda mtemp2
	sbc min12
	sta mtemp2
	lda mtemp3
	sbc min13
	sta mtemp3
	
	inc mres0
div_32x32_continue:
	dec mtemp4
	bne div_32x32_loop
	
	lda mtemp0
	sta rem0
	lda mtemp1
	sta rem1
	lda mtemp2
	sta rem2
	lda mtemp3
	sta rem3
	
	rts

div_fixed:
	txa
	pha
	lda #0
	sta temp0
	lda min03
	bpl div_fixed_pos_0
	
	sec
	ldx #0
div_fixed_inv_loop_0:
	lda min00,X
	eor #255
	adc #0
	sta min00,X
	inx
	txa
	cmp #4
	bne div_fixed_inv_loop_0
	lda #1
	eor temp0
	sta temp0
	
div_fixed_pos_0:
	lda min13
	bpl div_fixed_pos_1
	
	sec
	ldx #0
div_fixed_inv_loop_1:
	lda min10,X
	eor #255
	adc #0
	sta min10,X
	inx
	txa
	cmp #4
	bne div_fixed_inv_loop_1
	lda #1
	eor temp0
	sta temp0
	
div_fixed_pos_1:
	
	lda #0
	sta mres0
	sta mres1
	sta mres2
	sta mres3
	sta mtemp0
	sta mtemp1
	sta mtemp2
	sta mtemp3
	lda #56
	sta mtemp4
div_fixed_loop:
	asl mres0
	rol mres1
	rol mres2
	rol mres3
	
	asl min00
	rol min01
	rol min02
	rol min03
	rol mtemp0
	rol mtemp1
	rol mtemp2
	rol mtemp3
	
	sec
	lda mtemp0
	sbc min10
	lda mtemp1
	sbc min11
	lda mtemp2
	sbc min12
	lda mtemp3
	sbc min13
	bcc div_fixed_continue
	
	sec
	lda mtemp0
	sbc min10
	sta mtemp0
	lda mtemp1
	sbc min11
	sta mtemp1
	lda mtemp2
	sbc min12
	sta mtemp2
	lda mtemp3
	sbc min13
	sta mtemp3
	
	inc mres0
div_fixed_continue:
	dec mtemp4
	bne div_fixed_loop
	
	lda temp0
	beq div_fixed_pos_2
	
	sec
	ldx #0
div_fixed_inv_loop_2:
	lda mres0,X
	eor #255
	adc #0
	sta mres0,X
	inx
	txa
	cmp #4
	bne div_fixed_inv_loop_2
	
div_fixed_pos_2:
	pla
	tax
	rts

print_num_divs:
	.dword 1
	.dword 10
	.dword 100
	.dword 1000
	.dword 10000
	.dword 100000
	.dword 1000000
	.dword 10000000
	.dword 100000000
	.dword 1000000000
print_num:
	txa
	pha
	tya
	pha
	lda min03
	bpl print_num_pos
	lda #'-'
	sta $FFFF
	sec
	ldx #4
	ldy #0
print_num_inv_loop_0:
	lda min00,Y
	eor #$FF
	adc #0
	sta min00,Y
	iny
	dex
	bne print_num_inv_loop_0
print_num_pos:
	lda #0
	sta temp0
	ldx #10
print_num_loop:
	dex
	
	txa
	asl
	asl
	tay
	
	lda print_num_divs,Y
	sta min10
	iny
	lda print_num_divs,Y
	sta min11
	iny
	lda print_num_divs,Y
	sta min12
	iny
	lda print_num_divs,Y
	sta min13
	
	jsr div_32x32
	lda temp0
	bne print_num_print
	lda mres0
	bne print_num_print
	txa
	beq print_num_print
	jmp print_num_noprint
print_num_print:
	lda mres0
	clc
	adc #'0'
	sta $FFFF
	sta temp0
print_num_noprint:
	lda rem0
	sta min00
	lda rem1
	sta min01
	lda rem2
	sta min02
	lda rem3
	sta min03
	txa
	bne print_num_loop
	
	pla
	tay
	pla
	tax
	rts

print_fixed:
	txa
	pha
	tya
	pha
	lda min03
	bpl print_fixed_pos
	lda #'-'
	sta $FFFF
	sec
	ldx #4
	ldy #0
print_fixed_inv_loop_0:
	lda min00,Y
	eor #$FF
	adc #0
	sta min00,Y
	iny
	dex
	bne print_fixed_inv_loop_0
print_fixed_pos:
	lda min02
	pha
	lda min01
	pha
	lda min00
	pha
	lda min03
	sta min00
	lda #0
	sta min01
	sta min02
	sta min03
	jsr print_num
	lda #'.'
	sta $FFFF
	lda #0
	sta min03
	pla
	sta min00
	pla
	sta min01
	pla
	sta min02
	
	ldx #8
	lda #10
	sta min13
	lda #0
	sta min12
	sta min11
	sta min10
print_fixed_loop:
	jsr mul_fixed
	lda mres3
	clc
	adc #'0'
	sta $FFFF
	lda mres2
	sta min02
	lda mres1
	sta min01
	lda mres0
	sta min00
	dex
	bne print_fixed_loop
	
	pla
	tay
	pla
	tax
	rts

print_hex:
	sta temp0
	tya
	pha
	lda temp0
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
	tay
	lda temp0
	rts
	
m_ins_8x8:
.byte 5,6,57,8,233,108,0,3,25,8,255
div_ins_16x16:
.byte 1,33,0,25
.byte 23,78,3,108
.byte 0,28,1,1
.byte 200,55,0,0
.byte 0,8,0,2
.byte 0,2,200,55
.byte 200,55,0,88
.byte 255
mul_ins_32x32:
.byte 0,0,37,200,0,0,245,99
.byte 0,23,57,68,0,0,88,69
.byte 55,29,87,33,229,1,58,108
.byte 0,0,0,0,23,158,10,58
.byte 0,0,0,55,23,158,10,58
.byte 0,23,57,68,0,0,0,0
.byte 255
div_ins_32x32:
.byte 0,0,0,200,0,0,0,50
.byte 27,38,201,208,0,29,31,0
.byte 108,37,19,111,33,11,60,183
.byte 108,37,19,111,0,0,0,0
.byte 0,0,0,0,33,11,60,183
.byte 18,91,102,111,0,37,131,19
.byte 255
print_num_ins:
.dword 37222
.dword 27888576
.dword 1768900378
.dword 1
.dword 0
.dword $FFFFFFFB
.byte 255
hex_digits:
.asciiz "0123456789ABCDEF"
	
.byte 'E','O','F'

.segment "VECTORS"
.word NMI,RESET,IRQ
