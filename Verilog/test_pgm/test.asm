.feature string_escapes
.feature org_per_seg
.feature c_comments

PORT1_OUT  = $0201
PORT2_OUT  = $0202
PORT_IN    = $0208

mem_start = $80
port1_shadow = mem_start+1
port2_shadow = mem_start+2
counter = mem_start+6
temp0 = mem_start+7
temp1 = mem_start+8

min00 = mem_start+9
min01 = mem_start+10
min02 = mem_start+11
min03 = mem_start+12
min10 = mem_start+13
min11 = mem_start+14
min12 = mem_start+15
min13 = mem_start+16
mres0 = mem_start+17
mres1 = mem_start+18
mres2 = mem_start+19
mres3 = mem_start+20
mres4 = mem_start+21
mres5 = mem_start+22
mres6 = mem_start+23
mres7 = mem_start+24
mtemp0 = mem_start+25
mtemp1 = mem_start+26
mtemp2 = mem_start+27
mtemp3 = mem_start+28
mtemp4 = mem_start+29
mtemp5 = mem_start+30
mtemp6 = mem_start+31

loopi0 = mem_start+32
loopi1 = mem_start+33
col_buff = mem_start+34
xpos = mem_start+35
ypos = mem_start+36

; Mandel vars
C1 = mem_start+40
C2 = mem_start+44
C3 = mem_start+48
C4 = mem_start+52
C_IM = mem_start+56
C_RE = mem_start+60
MAN_X = mem_start+64
MAN_Y = mem_start+68
MAN_XX = mem_start+72
MAN_YY = mem_start+76
ITERATION = mem_start+80

rem0 = mem_start+81
rem1 = mem_start+82
rem2 = mem_start+83
rem3 = mem_start+84

width = 128
height = 64
total_loops = 8192

; Constants
W_D2 = 64
H_D2 = 32

ZOOM = 16000000
RE = 0
IMAG = 0
MAX_ITER = 128

.segment "CODE"
NMI:
	rti
IRQ:
	rti
RESET:
	ldx #$FF
	txs
	lda #0
	sta mem_start
	cld
	clv
	
	lda #%00001100
	sta PORT2_OUT
	sta port2_shadow
	
	lda #%01010000
	sta PORT1_OUT
	sta port1_shadow
	;jsr init_psg
	jsr reset_lcd
	
	jsr clear_lcd
	jsr lcd_select
	
mandel_calc_constants_c1:
	; res = 4 / width
	lda #0
	sta min00
	sta min01
	sta min02
	lda #4
	sta min03
	lda #0
	sta min10
	sta min11
	sta min12
	lda #width
	sta min13
	jsr div_fixed
	; C1 = res * ZOOM
	lda mres0
	sta min00
	lda mres1
	sta min01
	lda mres2
	sta min02
	lda mres3
	sta min03
	lda #ZOOM&255
	sta min10
	lda #(ZOOM>>8)&255
	sta min11
	lda #(ZOOM>>16)&255
	sta min12
	lda #(ZOOM>>24)&255
	sta min13
	jsr mul_fixed
	lda mres0
	sta C1
	sta min10
	lda mres1
	sta C1+1
	sta min11
	lda mres2
	sta C1+2
	sta min12
	lda mres3
	sta C1+3
	sta min13
	; C2 = W_D2 * C1
	lda #0
	sta min00
	sta min01
	sta min02
	lda #W_D2
	sta min03
	jsr mul_fixed
	lda mres0
	sta C2
	lda mres1
	sta C2+1
	lda mres2
	sta C2+2
	lda mres3
	sta C2+3
	
mandel_calc_constants_c4:
	; res = 2 / height
	lda #0
	sta min00
	sta min01
	sta min02
	lda #2
	sta min03
	lda #0
	sta min10
	sta min11
	sta min12
	lda #height
	sta min13
	jsr div_fixed
	; C4 = res * ZOOM
	lda mres0
	sta min00
	lda mres1
	sta min01
	lda mres2
	sta min02
	lda mres3
	sta min03
	lda #ZOOM&255
	sta min10
	lda #(ZOOM>>8)&255
	sta min11
	lda #(ZOOM>>16)&255
	sta min12
	lda #(ZOOM>>24)&255
	sta min13
	jsr mul_fixed
	lda mres0
	sta C4
	sta min10
	lda mres1
	sta C4+1
	sta min11
	lda mres2
	sta C4+2
	sta min12
	lda mres3
	sta C4+3
	sta min13
	; C3 = H_D2 * C4
	lda #0
	sta min00
	sta min01
	sta min02
	lda #H_D2
	sta min03
	jsr mul_fixed
	lda mres0
	sta C3
	lda mres1
	sta C3+1
	lda mres2
	sta C3+2
	lda mres3
	sta C3+3
	
	lda #0
	sta loopi0
	sta loopi1
	lda #7
	sta ypos
	jsr lcd_sety
	lda #width
	sta xpos
mandel_loop_main:
	jsr lcd_unselect
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	jsr lcd_select
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	lda loopi0
	and #7
	beq col_loop_done
	jmp col_loop_not_done
col_loop_done:
	lda xpos
	jsr lcd_setx
	lda col_buff
	jsr lcd_data
	
	dec xpos
	lda #255
	cmp xpos
	bne not_at_end_of_row
	jsr lcd_unselect
	nop
	nop
	nop
	nop
	;jsr boop
	jsr lcd_select
	nop
	nop
	nop
	nop
	lda #width-1
	sta xpos
	jsr lcd_setx
	dec ypos
	lda ypos
	jsr lcd_sety
not_at_end_of_row:
	lda xpos
	jsr lcd_setx
	lda #0
	sta col_buff
	
	; Recompute C_RE
	; res = col * C1
	lda #0
	sta min00
	sta min01
	sta min02
	lda xpos
	eor #127
	sta min03
	lda C1
	sta min10
	lda C1+1
	sta min11
	lda C1+2
	sta min12
	lda C1+3
	sta min13
	jsr mul_fixed
	; res = res + RE
	clc
	lda mres0
	adc #RE&255
	sta mres0
	lda mres1
	adc #(RE>>8)&255
	sta mres1
	lda mres2
	adc #(RE>>16)&255
	sta mres2
	lda mres3
	adc #(RE>>24)&255
	sta mres3
	; C_RE = res - C2
	sec
	lda mres0
	sbc C2
	sta C_RE
	lda mres1
	sbc C2+1
	sta C_RE+1
	lda mres2
	sbc C2+2
	sta C_RE+2
	lda mres3
	sbc C2+3
	sta C_RE+3
	
col_loop_not_done:
	lda xpos
	jsr lcd_setx
	lda ypos
	jsr lcd_sety
	lda loopi0
	and #7
	tax
	lda col_buff
	ora bit_mask,X
	jsr lcd_data
	
	; Compute C_IM
	; res = row * C4
	lda #0
	sta min00
	sta min01
	sta min02
	
	lda ypos
	eor #7
	asl
	asl
	asl
	sta temp0
	lda loopi0
	and #7
	clc
	adc temp0
	sta min03
	
	lda C4
	sta min10
	lda C4+1
	sta min11
	lda C4+2
	sta min12
	lda C4+3
	sta min13
	jsr mul_fixed
	; res = res + IMAG
	clc
	lda mres0
	adc #IMAG&255
	sta mres0
	lda mres1
	adc #(IMAG>>8)&255
	sta mres1
	lda mres2
	adc #(IMAG>>16)&255
	sta mres2
	lda mres3
	adc #(IMAG>>24)&255
	sta mres3
	; C_IM = Y = res - C3
	sec
	lda mres0
	sbc C3
	sta C_IM
	STA MAN_Y
	lda mres1
	sbc C3+1
	sta C_IM+1
	sta MAN_Y+1
	lda mres2
	sbc C3+2
	sta C_IM+2
	sta MAN_Y+2
	lda mres3
	sbc C3+3
	sta C_IM+3
	sta MAN_Y+3
	
	; X = c_re
	lda C_RE
	sta MAN_X
	lda C_RE+1
	sta MAN_X+1
	lda C_RE+2
	sta MAN_X+2
	lda C_RE+3
	sta MAN_X+3
	
	; iteration = 0
	lda #0
	sta ITERATION
	sta ITERATION+1
mandel_calc_loop:
	; yy = y * y
	lda MAN_Y
	sta min00
	sta min10
	lda MAN_Y+1
	sta min01
	sta min11
	lda MAN_Y+2
	sta min02
	sta min12
	lda MAN_Y+3
	sta min03
	sta min13
	jsr mul_fixed
	lda mres0
	sta MAN_YY
	lda mres1
	sta MAN_YY+1
	lda mres2
	sta MAN_YY+2
	lda mres3
	sta MAN_YY+3
	; res = x * y
	lda MAN_X
	sta min00
	lda MAN_X+1
	sta min01
	lda MAN_X+2
	sta min02
	lda MAN_X+3
	sta min03
	lda MAN_Y
	sta min10
	lda MAN_Y+1
	sta min11
	lda MAN_Y+2
	sta min12
	lda MAN_Y+3
	sta min13
	jsr mul_fixed
	; res = res << 1
	asl mres0
	rol mres1
	rol mres2
	rol mres3
	; Y = res + c_im
	clc
	lda mres0
	adc C_IM
	sta MAN_Y
	lda mres1
	adc C_IM+1
	sta MAN_Y+1
	lda mres2
	adc C_IM+2
	sta MAN_Y+2
	lda mres3
	adc C_IM+3
	sta MAN_Y+3
	; res = X * X
	lda MAN_X
	sta min00
	sta min10
	lda MAN_X+1
	sta min01
	sta min11
	lda MAN_X+2
	sta min02
	sta min12
	lda MAN_X+3
	sta min03
	sta min13
	jsr mul_fixed
	; XX = res
	; res = res - YY
	sec
	lda mres0
	sta MAN_XX
	sbc MAN_YY
	sta mres0
	lda mres1
	sta MAN_XX+1
	sbc MAN_YY+1
	sta mres1
	lda mres2
	sta MAN_XX+2
	sbc MAN_YY+2
	sta mres2
	lda mres3
	sta MAN_XX+3
	sbc MAN_YY+3
	sta mres3
	; X = res + C_RE
	clc
	lda mres0
	adc C_RE
	sta MAN_X
	lda mres1
	adc C_RE+1
	sta MAN_X+1
	lda mres2
	adc C_RE+2
	sta MAN_X+2
	lda mres3
	adc C_RE+3
	sta MAN_X+3
	
	; check if xx + yy <= 4
	clc
	lda MAN_XX
	adc MAN_YY
	lda MAN_XX+1
	adc MAN_YY+1
	lda MAN_XX+2
	adc MAN_YY+2
	lda MAN_XX+3
	adc MAN_YY+3
	cmp #4
	bmi mandel_calc_continue
	jmp mandel_exit_overflow
mandel_calc_continue:
	sec
	lda ITERATION
	adc #0
	sta ITERATION
	lda ITERATION+1
	adc #0
	sta ITERATION+1
	
	lda ITERATION+1
	eor #(MAX_ITER>>8)&255
	bne mandel_calc_continue2
	lda ITERATION
	eor #MAX_ITER&255
	bne mandel_calc_continue2
	jmp mandel_exit_inside
mandel_calc_continue2:
	jmp mandel_calc_loop
mandel_exit_inside:
	sec
	jmp mandel_put_pixel
mandel_exit_overflow:
	clc
mandel_put_pixel:
	lda loopi0
	and #7
	tax
	inx
	lda #0
	ror
rsh_loop:
	dex
	beq rsh_loop_end
	clc
	ror
	jmp rsh_loop
rsh_loop_end:
	ora col_buff
	sta col_buff
	
	clc
	lda loopi0
	adc #1
	sta loopi0
	lda loopi1
	adc #0
	sta loopi1
	lda loopi1
	eor #(total_loops>>8)&255
	bne mandel_loop_main_continue
	lda loopi0
	eor #total_loops&255
	bne mandel_loop_main_continue
	jmp mandel_loop_main_exit
mandel_loop_main_continue:
	jmp mandel_loop_main
mandel_loop_main_exit:
	jsr lcd_unselect
	
	lda port2_shadow
	ora #128
	sta PORT2_OUT
	lda port2_shadow
	and #127
	sta PORT2_OUT
	
	lda #3
	sta temp1
beep_beep_beep:
	;jsr beep
	jsr delay
	jsr delay
	jsr delay
	jsr delay
	jsr delay
	jsr delay
	dec temp1
	bne beep_beep_beep
	
	ldx #0
.byte $FF,$FF,$FF
	nop
	nop
	nop
	nop

loop:
	;lda port1_shadow
	;eor #128
	;sta port1_shadow
	;sta PORT1_OUT

	lda #24
	jsr long_delay
	jmp loop
	
	; Data on stack
spi_send:
	ldx #8
	lda port2_shadow
	and #%11001111
	sta PORT2_OUT
	sta port2_shadow
	pla
spi_send_loop:
	rol
	sta temp1
	lda #0
	ror
	ror
	ror
	ora port2_shadow
	sta PORT2_OUT
	nop
	nop
	ora #16
	sta PORT2_OUT
	nop
	nop
	and #%11101111
	sta PORT2_OUT
	nop
	nop
	lda temp1
	dex
	bne spi_send_loop
	rts
	
reset_lcd:
	lda port2_shadow
	and #%11111101
	ora #%00001100
	sta PORT2_OUT
	jsr delay
	ora #%00000010
	sta PORT2_OUT
	sta port2_shadow
	jsr delay
	jsr lcd_select
	ldy #0
reset_lcd_loop:
	lda lcd_rst_seq,Y
	beq reset_lcd_loop_exit
	iny
	jsr lcd_cmd
	jsr delay
	jmp reset_lcd_loop
reset_lcd_loop_exit:
	jmp delay
	
lcd_select:
	lda port2_shadow
	and #%11111011
	sta PORT2_OUT
	sta port2_shadow
	nop
	nop
	rts
	
lcd_unselect:
	lda port2_shadow
	ora #%00000100
	sta PORT2_OUT
	sta port2_shadow
	nop
	nop
	rts
	
lcd_cmd:
	pha
	lda port2_shadow
	and #%10111111
	sta PORT2_OUT
	sta port2_shadow
	nop
	nop
	jmp spi_send
	
lcd_data:
	pha
	lda port2_shadow
	ora #%01000000
	sta PORT2_OUT
	sta port2_shadow
	nop
	nop
	jmp spi_send
	
lcd_setx:
	pha
	ror
	ror
	ror
	ror
	and #15
	ora #$10
	jsr lcd_cmd
	pla
	and #15
	jmp lcd_cmd
	
lcd_sety:
	and #7
	ora #$B0
	jmp lcd_cmd
	
clear_lcd:
	jsr lcd_select
	lda #8
	sta counter
lcd_data_loop_outer:
	lda #0
	jsr lcd_setx
	lda counter
	sec
	sbc #1
	jsr lcd_sety
	lda #128
lcd_data_loop:
	pha
	lda #0
	jsr lcd_data
	pla
	sec
	sbc #1
	bne lcd_data_loop
	dec counter
	bne lcd_data_loop_outer
	
	jsr lcd_unselect
	jmp delay
	
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

div_fixed:
	txa
	pha
	
	lda #0
	sta mres0
	sta mres1
	sta mres2
	sta mres3
	sta mtemp0
	sta mtemp1
	sta mtemp2
	sta mtemp3
	sta mtemp4
	lda #56
	sta mtemp5
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
	rol mtemp4
	
	sec
	lda mtemp0
	sbc min10
	lda mtemp1
	sbc min11
	lda mtemp2
	sbc min12
	lda mtemp3
	sbc min13
	lda mtemp4
	sbc #0
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
	lda mtemp4
	sbc #0
	sta mtemp4
	
	inc mres0
div_fixed_continue:
	dec mtemp5
	bne div_fixed_loop
	
	pla
	tax
	rts

delay:
	pha
	lda #0
delay_loop:
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	clc
	adc #1
	bcc delay_loop
	pla
	rts

long_delay:
	jsr delay
	sec
	sbc #1
	bcs long_delay
	rts

beep:
	lda #%00110101
	jsr psg_write
	lda #%00010000
	jsr psg_write
	lda #%00011101
	jsr psg_write
	jsr delay
	jsr delay
	jsr delay
	jsr delay
	jsr delay
	jsr delay
	lda #%11111101
	jmp psg_write

boop:
	lda #%01100001
	jsr psg_write
	lda #%00101000
	jsr psg_write
	lda #%00011001
	jsr psg_write
	jsr delay
	jsr delay
	jsr delay
	jsr delay
	jsr delay
	jsr delay
	lda #%11111001
	jmp psg_write

psg_write:
	pha
	lda port1_shadow
	and #%11110000
	sta port1_shadow
	pla
	pha
	and #%00001111
	ora port1_shadow
	sta PORT1_OUT
	sta port1_shadow
	
	lda port2_shadow
	and #%00001111
	sta port2_shadow
	pla
	and #%11110000
	ora port2_shadow
	sta PORT2_OUT
	sta port2_shadow
	
	lda port1_shadow
	and #%10111111
	sta PORT1_OUT
	nop
	nop
	nop
	nop
	nop
	nop
	ora #%01000000
	sta PORT1_OUT
	sta port1_shadow
	nop
	nop
	nop
	nop
	rts

init_psg:
	lda #%11111001
	jsr psg_write
	lda #%11111011
	jsr psg_write
	lda #%11111101
	jsr psg_write
	lda #%11111111
	jsr psg_write
	
	lda #64
	jsr long_delay
	
	lda #%00110001
	jsr psg_write
	lda #%00100000
	jsr psg_write
	
	lda #%00011001
	jsr psg_write
	lda #16
	jsr long_delay
	lda #%11111001
	jsr psg_write
	lda #4
	jsr long_delay
	lda #%00011001
	jsr psg_write
	lda #16
	jsr long_delay
	lda #%11111001
	jsr psg_write
	
	lda #64
	jsr long_delay
	rts

lcd_rst_seq:
.byte $A2, $A0, $C8, $27, $2F, $81, 19, $40, $AF, $A6, 0

bit_mask:
.byte 128,64,32,16,8,4,2,1

.byte 'E','O','F'

.segment "VECTORS"
.word NMI,RESET,IRQ
