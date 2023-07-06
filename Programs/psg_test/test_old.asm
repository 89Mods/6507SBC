.feature string_escapes
.feature org_per_seg
.feature c_comments

PORT1_OUT = $0201
PORT2_OUT = $0202
PORT_IN   = $0208

mem_start = $80
port1_shadow = mem_start
port2_shadow = mem_start+1
temp = mem_start+2

.segment "CODE"
NMI:
	rti
IRQ:
	rti
RESET:
	ldx #$FF
	txs
	lda #0
	sta port2_shadow
	sta temp
	
	lda #64
	sta PORT1_OUT
	sta port1_shadow
	jsr psg_delay
	
	lda #%11111001
	jsr psg_write
	lda #%11111011
	jsr psg_write
	lda #%11111101
	jsr psg_write
	lda #%11111111
	jsr psg_write
	
	jsr delay
	
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
	
	lda #%01100001
	jsr psg_write
	lda #%00101000
	jsr psg_write
	
loop:
	lda #24
	jsr long_delay
	
	lda #1
	eor port2_shadow
	sta PORT2_OUT
	sta port2_shadow
	
	lda PORT_IN
	and #1
	bne loop
	
	lda #%00011001
	jsr psg_write
	jsr delay
	jsr delay
	jsr delay
	jsr delay
	jsr delay
	lda #%11111001
	jsr psg_write
wait_for_btn_release:
	lda PORT_IN
	and #1
	beq wait_for_btn_release
	
	jmp loop

psg_write:
	pha
	and #%00001111
	sta temp
	lda port1_shadow
	and #%11110000
	ora temp
	sta PORT1_OUT
	sta port1_shadow
	
	pla
	and #%11110000
	sta temp
	lda port2_shadow
	and #%00001111
	ora temp
	sta PORT2_OUT
	sta port2_shadow
	
	lda port1_shadow
	and #%10111111
	sta PORT1_OUT
	jsr psg_delay
	ora 64
	sta PORT1_OUT
	jsr psg_delay
	rts

psg_delay:
	nop
	nop
	nop
	nop
	rts

long_delay:
	jsr delay
	sec
	sbc #1
	bcs long_delay
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
	clc
	adc #1
	bcc delay_loop
	pla
	rts

.byte 'E','O','F'

.segment "VECTORS"
.word NMI,RESET,IRQ
