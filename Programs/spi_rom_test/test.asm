.feature string_escapes
.feature org_per_seg
.feature c_comments

PORT1_OUT  = $0201
PORT2_OUT  = $0202
PORT_IN    = $0208

mem_start = $80
port1_shadow = mem_start+1
port2_shadow = mem_start+2
btn_state = mem_start+3
temp1 = mem_start+4
temp2 = mem_start+5
temp3 = mem_start+6
delay_lo = mem_start+7
delay_hi = mem_start+8
extend = mem_start+9

.segment "CODE"
NMI:
	rti
IRQ:
	rti
RESET:
	ldx #$FF
	txs
	cld
	clv
	lda #0
	sta mem_start
	sta btn_state
	
	lda #8
	sta PORT2_OUT
	sta port2_shadow
	lda #64
	sta PORT1_OUT
	sta port1_shadow
	jsr init_psg
	
	jsr rom_select
	lda #$90
	jsr spi_send
	lda #0
	jsr spi_send
	jsr spi_send
	jsr spi_send
	jsr spi_receive
	pha
	jsr spi_receive
	pha
	jsr rom_deselect
	
	pla
	cmp #$C2
	bne init_fail
	pla
	cmp #$10
	beq init_pass
init_fail:
	lda port1_shadow
	eor #128
	sta port1_shadow
	sta PORT1_OUT
	jmp init_fail
init_pass:
	jsr rom_select
	lda #$03
	jsr spi_send
	lda #0
	jsr spi_send
	lda #0
	jsr spi_send
	lda #0
	sta temp2
	jsr spi_send
seek_loop:
	jsr spi_receive
	cmp #$FF
	beq seek_loop_exit
	inc temp2
	bmi init_fail
	jmp seek_loop
seek_loop_exit:

loop:
	lda #0
	cmp extend
	bne do_extend
	jsr spi_receive
	cmp #$50
	beq vgm_note
	cmp #$61
	beq vgm_delay
	cmp #$63
	beq vgm_882
	cmp #$62
	beq vgm_735
	cmp #$FF
	beq vgm_extend
	cmp #$66
	bne do_not_end_song
	jmp end_song
do_not_end_song:
	jsr spi_receive_dummy
	jmp loop
do_extend:
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	dec extend
	jsr spi_receive_dummy
	jsr spi_receive_dummy
	jsr psg_write_dummy
	jmp loop
vgm_extend:
	jsr spi_receive
	sec
	sbc #1
	sta extend
	jsr psg_write_dummy
	jmp loop
vgm_note:
	jsr spi_receive_reverse
	jsr psg_write
	jmp loop
vgm_882:
	jsr spi_receive_dummy
	lda #$72
	sta delay_lo
	lda #$03
	sta delay_hi
	jmp vgm_delay_begin
vgm_735:
	jsr spi_receive_dummy
	lda #$DF
	sta delay_lo
	lda #$02
	sta delay_hi
	jmp vgm_delay_begin
vgm_delay:
	jsr spi_receive
	sta delay_lo
	jsr spi_receive
	sta delay_hi
	jmp vgm_delay_loop
vgm_delay_begin:
	lda delay_hi
	lsr
	sta delay_hi
	lda delay_lo
	ror
	sta delay_lo
	
	lda delay_hi
	lsr
	sta temp1
	lda delay_lo
	ror
	sta temp2
	lda temp1
	lsr
	sta temp1
	lda temp2
	ror
	sta temp2
	
	sec
	lda delay_lo
	sbc temp2
	sta delay_lo
	lda delay_hi
	sbc temp1
	sta delay_hi
vgm_delay_loop:
	lda delay_lo
	sec
	sbc #1
	sta delay_lo
	lda delay_hi
	sbc #0
	sta delay_hi
	lda #0
	ora delay_lo
	ora delay_hi
	bne vgm_delay_loop
	jmp loop
	
end_song:
	jsr rom_deselect
	lda #%11111001
	jsr psg_write
	lda #%11111011
	jsr psg_write
	lda #%11111101
	jsr psg_write
	lda #%11111111
	jsr psg_write
halt:
	nop
	lda #%11111001
	jsr psg_write
	lda port2_shadow
	eor #1
	sta PORT2_OUT
	sta port2_shadow
	lda #31
	jsr long_delay
	lda PORT_IN
	and #1
	bne halt
	jmp RESET
	
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
	
rom_select:
	lda port2_shadow
	and #%11110111
	sta port2_shadow
	sta PORT2_OUT
	rts
	
rom_deselect:
	lda port2_shadow
	ora #8
	sta port2_shadow
	sta PORT2_OUT
	rts
	
spi_send:
	pha
	txa
	sta temp1
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
	lda port2_shadow
	sta PORT2_OUT
	nop
	nop
	lda temp1
	tax
	rts
	
spi_receive_dummy:
	txa
	sta temp1
	ldx #8
	lda #0
	sta temp3
	lda port2_shadow
	and #%11001111
	sta PORT2_OUT
	sta port2_shadow
spi_receive_dummy_loop:
	lda #16
	ora port2_shadow
	sta temp2
	nop
	nop
	lda PORT_IN
	asl
	lda temp3
	rol
	sta temp3
	lda port2_shadow
	sta temp2
	nop
	nop
	dex
	bne spi_receive_dummy_loop
	lda temp1
	tax
	lda temp3
	rts
	
spi_receive:
	txa
	sta temp1
	ldx #8
	lda #0
	sta temp3
	lda port2_shadow
	and #%11001111
	sta PORT2_OUT
	sta port2_shadow
spi_receive_loop:
	lda #16
	ora port2_shadow
	sta PORT2_OUT
	nop
	nop
	lda PORT_IN
	asl
	lda temp3
	rol
	sta temp3
	lda port2_shadow
	sta PORT2_OUT
	nop
	nop
	dex
	bne spi_receive_loop
	lda temp1
	tax
	lda temp3
	rts
	
spi_receive_reverse:
	txa
	sta temp1
	ldx #8
	lda #0
	sta temp3
	lda port2_shadow
	and #%11001111
	sta PORT2_OUT
	sta port2_shadow
spi_receive_reverse_loop:
	lda #16
	ora port2_shadow
	sta PORT2_OUT
	lda PORT_IN
	nop
	nop
	asl
	lda temp3
	ror
	sta temp3
	lda port2_shadow
	sta PORT2_OUT
	nop
	nop
	dex
	bne spi_receive_reverse_loop
	lda temp1
	tax
	lda temp3
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
	
psg_write_dummy:
	pha
	lda port1_shadow
	and #%11110000
	sta temp1
	pla
	pha
	and #%00001111
	ora port1_shadow
	sta temp1
	sta temp1
	
	lda port2_shadow
	and #%00001111
	sta temp1
	pla
	and #%11110000
	ora port2_shadow
	sta temp1
	sta temp1
	
	lda port1_shadow
	and #%10111111
	sta temp1
	nop
	nop
	nop
	nop
	nop
	nop
	ora #%01000000
	sta temp1
	sta temp1
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
	jmp long_delay
	
.byte 'E','O','F'

.segment "VECTORS"
.word NMI,RESET,IRQ
