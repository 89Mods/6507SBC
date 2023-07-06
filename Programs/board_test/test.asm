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

; LCD pinout: LED, LED, RS, E, D7, D6, D5, D4

lcd_init1 = %00000011
lcd_init2 = %00000010
lcd_init3 = %00000000
lcd_init4 = %00001111

lcd_clr_lo = %00000000
lcd_clr_hi = %00000001

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
	sta btn_state
	
	lda #64
	sta PORT1_OUT
	sta port1_shadow
	jsr init_psg
	
	lda #lcd_init1
	jsr lcd_cmd
	lda #lcd_init2
	jsr lcd_cmd
	lda #lcd_init3
	jsr lcd_cmd
	lda #lcd_init4
	jsr lcd_cmd
	lda #lcd_clr_lo
	jsr lcd_cmd
	lda #lcd_clr_hi
	jsr lcd_cmd
	
	ldx #0
print_loop:
	lda hello_text,X
	beq print_loop_exit
	inx
	jsr lcd_data
	jmp print_loop
	
print_loop_exit:

loop:
	lda PORT_IN
	and #1
	beq skip_increment
	lda #0
	ora btn_state
	bpl btn_released

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
	jsr psg_write

	lda #0
	sta btn_state
btn_released:
	lda port2_shadow
	and #%11110000
	sta port2_shadow
	lda mem_start
	and #%00001111
	ora port2_shadow
	sta PORT2_OUT
	sta port2_shadow
	
	lda mem_start
	clc
	adc #1
	sta mem_start
	
	lda #%00001100
	jsr lcd_cmd
	lda #%00000000
	jsr lcd_cmd
	
	lda mem_start
	lsr
	lsr
	lsr
	lsr
	tax
	lda hex_digits,X
	jsr lcd_data
	lda mem_start
	and #15
	tax
	lda hex_digits,X
	jsr lcd_data
	jmp btn_held
	
skip_increment:
	lda #0
	ora btn_state
	bmi btn_held
	
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
	jsr psg_write
	lda #255
	sta btn_state
btn_held:
	
	lda port1_shadow
	eor #128
	sta port1_shadow
	sta PORT1_OUT

	lda #24
	jsr long_delay
	
	jmp loop
	
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
	
lcd_delay:
	pha
	lda #32
	clc
lcd_delay_loop:
	adc #1
	bcc lcd_delay_loop
	pla
	rts
	
lcd_cmd:
	pha
	lda port1_shadow
	and #192
	sta port1_shadow
	pla
	ora port1_shadow
	sta PORT1_OUT
	ora #16
	sta PORT1_OUT
	jsr lcd_delay
	and #192
	sta PORT1_OUT
	jsr lcd_delay
	rts
	
lcd_data:
	pha
	lda port1_shadow
	and #192
	sta port1_shadow
	pla
	pha
	lsr
	lsr
	lsr
	lsr
	ora port1_shadow
	ora #48
	sta PORT1_OUT
	jsr lcd_delay
	and #192
	sta PORT1_OUT
	jsr lcd_delay
	pla
	and #15
	ora port1_shadow
	ora #48
	sta PORT1_OUT
	jsr lcd_delay
	and #192
	sta PORT1_OUT
	jsr lcd_delay
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
	
hello_text:
.asciiz "Hi, I am 6507!"
.byte 0
hex_digits:
.asciiz "0123456789ABCDEF"
	
.byte 'E','O','F'

.segment "VECTORS"
.word NMI,RESET,IRQ
