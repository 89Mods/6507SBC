.feature string_escapes
.feature org_per_seg
.feature c_comments

PORT1_OUT  = $0201
PORT2_OUT  = $0202
PORT_IN    = $0208

mem_start = $80
port1_shadow = mem_start+1
port2_shadow = mem_start+2
bm_mode = mem_start+3
temp1 = mem_start+4
temp2 = mem_start+5
counter = mem_start+6
temp3 = mem_start+7
ptr_lo = mem_start+8
ptr_hi = mem_start+9
btn_state = mem_start+10

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
	sta bm_mode
	sta temp1
	sta temp2
	sta btn_state
	
	lda #%00001100
	sta PORT2_OUT
	sta port2_shadow
	
	lda #%01010000
	sta PORT1_OUT
	sta port1_shadow
	jsr init_psg
	jsr reset_lcd
	
	lda #24
	jsr long_delay
	
	jsr lcd_unselect
	jsr delay
	
	jsr write_bitmap
	
no_btn_press:
	lda #0
	sta btn_state
loop:
	lda port2_shadow
	eor #1
	sta PORT2_OUT
	sta port2_shadow
	lda #24
	jsr long_delay
	lda PORT_IN
	and #1
	bne no_btn_press
	lda btn_state
	bne loop
	lda bm_mode
	eor #$FF
	sta bm_mode
	lda #$55
	sta btn_state
	jsr boop
	jsr write_bitmap
	jsr beep
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
	sta temp3
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
	lda temp3
	dex
	bne spi_send_loop
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
	
write_bitmap:
	lda #(bitmap&255)
	sta ptr_lo
	lda #((bitmap/256)&255)
	sta ptr_hi
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
	;lda #$55
	ldy #0
	lda (ptr_lo),Y
	inc ptr_lo
	bne no_ptr_carry
	inc ptr_hi
no_ptr_carry:
	eor bm_mode
	jsr lcd_data
	pla
	sec
	sbc #1
	bne lcd_data_loop
	dec counter
	bne lcd_data_loop_outer
	
	jsr lcd_unselect
	jmp delay
	
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
	
bitmap:
.byte $00, $00, $00, $00, $00, $00, $00, $00, $07, $7f, $3f, $1f, $0f, $03, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $07, $0f, $1e, $1e, $1e, $3e, $3f, $1f, $1f, $0f, $07, $03, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $f0, $fe, $ff, $ff, $ff, $ff, $ff, $ff, $3f, $1f, $0f, $03, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $07, $7c, $e0, $80, $00, $00, $00, $00, $00, $00, $00, $c0, $e0, $ff, $ff, $ff, $ff, $3f, $07, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $1f, $0f, $07, $07, $03, $01, $01, $00, $00, $00, $c0, $f8, $fe, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $7f, $3f, $0f, $07, $01, $06, $0f, $0f, $0f, $0f, $0f, $0f, $07, $07, $07, $07, $03, $03, $01, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $0f, $7f, $ff, $ff, $ff, $fc, $ff, $ff, $ff, $3f, $07, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $c0, $f0, $fc, $fe, $ff, $ff, $ff, $ff, $7f, $3f, $1f, $1f, $0f, $c7, $f3, $fd, $fe, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $7f, $1f, $07, $01, $00, $00, $00, $00, $80, $80, $80, $c0, $c0, $e0, $f0, $f0, $f8, $7c, $3f, $1f, $0f, $03, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $07, $3f, $ff, $ff, $ff, $fc, $e0, $00, $00, $80, $e0, $fc, $ff, $ff, $ff, $3f, $07, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $80, $c0, $e0, $f0, $fd, $fe, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $7f, $bf, $df, $ef, $f7, $fb, $fd, $fe, $ff, $ff, $ff, $ff, $ff, $3f, $07, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $c0, $f0, $ff, $ff, $7f, $0f, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $03, $1f, $ff, $ff, $ff, $fe, $fe, $8e, $0e, $0e, $0e, $0e, $0e, $0e, $0e, $8e, $ee, $fe, $ff, $ff, $ff, $3f, $07, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $3c, $1e, $1f, $1f, $1f, $0f, $0f, $0f, $ef, $f7, $77, $b7, $c3, $f3, $fb, $f9, $fd, $fc, $fe, $fe, $ff, $ff, $ff, $ff, $ff, $bf, $df, $e7, $fb, $fc, $ff, $ff, $ff, $1f, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $9f, $ff, $ff, $fe, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $03, $0f, $7f, $ff, $ff, $ff, $f8, $c0, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $80, $f0, $fe, $ff, $ff, $ff, $3f, $07, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $80, $c0, $c0, $e0, $f0, $f0, $f8, $f8, $fc, $fe, $fe, $ff, $ff, $ff, $ff, $7f, $7f, $bf, $bf, $df, $cf, $ef, $f7, $f3, $fb, $fd, $7e, $9e, $ef, $fb, $fe, $3f, $01, $00, $00, $00, $00, $01, $03, $07, $0f, $3f, $fe, $fc, $f0, $c0, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $30, $30, $70, $f0, $f0, $f0, $f0, $f0, $f0, $f0, $30, $30, $30, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $80, $f0, $fc, $ff, $ff, $ff, $3f, $07, $01, $00, $00, $00, $00, $00, $00, $00, $01, $07, $1e, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $80, $40, $60, $b0, $b0, $f8, $d8, $dc, $dc, $dc, $de, $de, $de, $de, $de, $de, $7e, $6e, $b6, $d6, $88, $e4, $08, $70, $78, $f0, $f0, $e0, $c0, $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $80, $e0, $f0, $f0, $f8, $f8, $7c, $7c, $7c, $7c, $78, $f0, $e0, $c0, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

.byte 'E','O','F'

.segment "VECTORS"
.word NMI,RESET,IRQ
