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

SEMIQUAVER = 1
QUAVER = SEMIQUAVER+SEMIQUAVER
CROTCHET = QUAVER+QUAVER
MINIM = CROTCHET+CROTCHET
MINIM_DOT = MINIM+CROTCHET
SEMIBREVE = MINIM+MINIM

REST = $00
C3   = $01
C3S  = $02
D3   = $03
D3S  = $04
E3   = $05
F3   = $06
F3S  = $07
G3   = $08
A3F  = $09
A3   = $0A
A3S  = $0B
B3   = $0C

C4   = $0D
C4S  = $0E
D4   = $0F
D4S  = $10
E4   = $11
F4   = $12
F4S  = $13
G4   = $14
A4F  = $15
A4   = $16
A4S  = $17
B4   = $18

C5   = $19
C5S  = $1A
D5   = $1B
D5S  = $1C
E5   = $1D
F5   = $1E
F5S  = $1F
G5   = $20
A5F  = $21
A5   = $22
A5S  = $23
B5   = $24

C6   = $25
C6S  = $26
D6   = $27
D6S  = $28
E6   = $29
F6   = $2A
F6S  = $2B
G6   = $2C
A6F  = $2D
A6   = $2E
A6S  = $2F
B6   = $30

C7   = $31

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
	
	lda #64
	sta PORT1_OUT
	sta port1_shadow
	
	jsr init_psg
	
	ldx #0
	
loop:
	lda #%11111001
	jsr psg_write
	jsr delay
	lda song_data,X
	cmp #$FF
	beq halt
	inx
	asl
	tay
	lda freq_tbl,Y
	iny
	ora #1
	jsr psg_write
	lda freq_tbl,Y
	jsr psg_write
	lda #%00011001
	jsr psg_write
	lda song_data,X
	inx
	asl
	asl
	asl
	jsr long_delay

	jmp loop
	
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
	beq RESET
	jmp halt

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

freq_tbl:
.byte $d0, $34, $c0, $54, $b0, $e4, $90, $a4, $10, $c4, $10, $84, $50, $f8, $b0, $b8
.byte $40, $38, $90, $58, $80, $98, $d0, $e8, $a0, $68, $80, $a8, $70, $c8, $30, $48
.byte $30, $88, $30, $08, $b0, $f0, $70, $70, $80, $70, $20, $b0, $10, $30, $b0, $d0
.byte $40, $d0, $10, $50, $f0, $90, $60, $90, $70, $10, $60, $10, $70, $e0, $e0, $e0
.byte $00, $e0, $50, $60, $20, $60, $70, $a0, $90, $a0, $20, $a0, $f0, $20, $d0, $20
.byte $e0, $20, $c0, $20, $f0, $c0, $d0, $c0, $10, $c0, $a0, $c0, $40, $c0, $f0, $40
.byte $30, $40, $50, $40

song_data:
.byte     C5, CROTCHET
.byte     C5, QUAVER
.byte     B4, QUAVER
.byte     A4, CROTCHET
.byte     A4, CROTCHET
.byte     G4, CROTCHET
.byte     G4, QUAVER
.byte     F4, QUAVER
.byte     E4, CROTCHET
.byte     E4, QUAVER
.byte     F4, QUAVER
.byte     G4, CROTCHET
.byte     C4, CROTCHET
.byte     D4, CROTCHET
.byte     F4, CROTCHET
.byte     E4, CROTCHET
.byte     D4, CROTCHET
.byte     C4, MINIM
.byte     C5, QUAVER
.byte     D5, QUAVER
.byte     C5, QUAVER
.byte     A4, QUAVER
.byte     B4, CROTCHET
.byte     G4, CROTCHET
.byte     C5, QUAVER
.byte     D5, QUAVER
.byte     C5, QUAVER
.byte     A4, QUAVER
.byte     B4, CROTCHET
.byte     G4, CROTCHET
.byte     C5, QUAVER
.byte     D5, QUAVER
.byte     C5, QUAVER
.byte     B4, QUAVER
.byte     A4, CROTCHET
.byte     D5, CROTCHET
.byte     B4, CROTCHET
.byte     A4, CROTCHET
.byte     G4, CROTCHET
.byte     E4, QUAVER
.byte     F4, QUAVER
.byte     G4, CROTCHET
.byte     C5, QUAVER
.byte     B4, QUAVER
.byte     A4, CROTCHET
.byte     A4, CROTCHET
.byte     G4, CROTCHET
.byte     G4, QUAVER
.byte     F4, QUAVER
.byte     E4, CROTCHET
.byte     E4, QUAVER
.byte     F4, QUAVER
.byte     G4, CROTCHET
.byte     C4, CROTCHET
.byte     D4, CROTCHET
.byte     F4, CROTCHET
.byte     E4, CROTCHET
.byte     D4, CROTCHET
.byte     C4, MINIM
.byte     $FF

.byte 'E','O','F'

.segment "VECTORS"
.word NMI,RESET,IRQ
