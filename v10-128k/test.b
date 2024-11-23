; LC256 Ramtest - Testcode KB0
; for ACME assembling by Vossi 11/2024, last update 11/2024
; v1.0 initial - special pcb v.1.0 128K-version
!cpu 65c02	; 6502, 6510, 65c02, 65816
!ct scr		; Standard text/char conversion table -> pet = petscii
!to "test.bin", plain
!source "defines.b"
!source "macros.b"
; ***************************************** TEST CODE *********************************************
!initmem FILL
!zone testcode
*= TESTCODE
	ldx #$fe			; reset stack
	txs

Test:	ldx #<(Screen+4*COLS+9)		; reset to first result screen position
	stx result_pointer 
	ldx #>(Screen+4*COLS+9)
	stx result_pointer+1

tstram0:lda #0
	sta temp			; clear test flag (0=ok)
; TEST $00, $ff
	+st16i pointer, $0400		; ramtest start
	ldy #0
r0tst00:lda #$00			; test byte $00
	sta (pointer),y
	cmp (pointer),y
	beq r0tstff			; ok
	lda #$80
	sta temp			; bad flag
r0tstff:lda #$ff			; test byte $ff
	sta (pointer),y
	cmp (pointer),y
	beq r0t00nx			; ok
	lda #$80
	sta temp			; bad flag
r0t00nx:iny
	bne r0tst00			; next byte
	inc pointer+1			; inc page
	lda pointer+1
	cmp #$80			; finished RAM0?
	bne r0tst00			; no.. next page
; TEST $5a, $a5
	+st16i pointer, $0400		; ramtest start
	; .y already 0
r0tst5a:lda #$5a			; test byte $5a
	sta (pointer),y
	cmp (pointer),y
	beq r0tsta5			; ok
	lda #$80
	sta temp			; bad flag
r0tsta5:lda #$a5			; test byte $a5
	sta (pointer),y
	cmp (pointer),y
	beq r0t5anx			; ok
	lda #$80
	sta temp			; bad flag
r0t5anx:iny
	bne r0tst5a			; next byte
	inc pointer+1			; inc page
	lda pointer+1
	cmp #$80			; finished RAM0?
	bne r0tst5a			; no.. next page
; TEST $aa, second byte $55
	+st16i pointer, $0400		; ramtest start
	; .y already 0
r0tstaa:lda #$aa			; test 1.byte $aa
	sta (pointer),y
	iny
	lda #$55			; test 2.byte $55
	sta (pointer),y
	dey
	lda (pointer),y
	cmp #$aa
	beq r0tst55			; ok
	lda #$80
	sta temp			; bad flag
r0tst55:iny
	lda (pointer),y
	cmp #$55
	beq r0taanx			; ok
	lda #$80
	sta temp			; bad flag
r0taanx:iny
	bne r0tstaa			; next byte
	inc pointer+1			; inc page
	lda pointer+1
	cmp #$80			; finished RAM0?
	bne r0tstaa			; no.. next page
; TEST address lowbyte
	+st16i pointer, $0400		; ramtest start
	; .y already 0
r0tstlo:tya				; store address lowbyte
	sta (pointer),y
	iny
	bne r0tstlo			; next byte
	inc pointer+1			; inc page
	lda pointer+1
	cmp #$80			; finished RAM0?
	bne r0tstlo			; no.. next page
	+st16i pointer, $0400		; ramtest start
	; .y already 0
r0chklo:tya				; check address lowbyte
	cmp (pointer),y
	beq r0tlonx			; ok
	lda #$80
	sta temp			; bad flag
r0tlonx:iny
	bne r0chklo			; next byte
	inc pointer+1			; inc page
	lda pointer+1
	cmp #$80			; finished RAM0?
	bne r0chklo			; no.. next page
; TEST address highbyte
	+st16i pointer, $0400		; ramtest start
	; .y already 0, address highbyte already in .a
r0tsthi:sta (pointer),y
	iny
	bne r0tsthi			; next byte
	inc pointer+1			; inc page
	lda pointer+1
	cmp #$80			; finished RAM0?
	bne r0tsthi			; no.. next page
	+st16i pointer, $0400		; ramtest start
	; .y already 0, address highbyte already in .a
r0chkhi:cmp (pointer),y
	beq r0thinx			; ok
	lda #$80
	sta temp			; bad flag
r0thinx:iny
	bne r0chkhi			; next byte
	inc pointer+1			; inc page
	lda pointer+1
	cmp #$80			; finished RAM0?
	bne r0chkhi			; no.. next page
; print result
	bit temp			; bank ok?
	bpl ram0ok			; yes.. print ok
	jsr TestBAD
	jmp r0nxbnk			; next bank

ram0ok:	jsr TestOK
; next bank
r0nxbnk:ldx mmu
	cpx #$0f			; last bank?
	beq r0bnkst
	inx				; inc bank
	stx mmu
	jmp tstram0			; test next bank
; store bank no
	; last bank in .a
r0bnkst:ldx #<(Screen+4*COLS+9)		; reset to first result screen position
	stx result_pointer 
	ldx #>(Screen+4*COLS+9)
	stx result_pointer+1

	ldx #$00			; RAM0 start $0400
	stx pointer
r0bnklp:ldx #$04
	stx pointer+1
	ldy #0
r0bstlp:sta (pointer),y
	iny
	bne r0bstlp			; next byte
	inc pointer+1			; inc page
	ldx pointer+1
	cpx #$80			; finished RAM0?
	bne r0bstlp			; no.. next page
; decrease bank
	cmp #$00			; first bank reached?
	beq r0bchk			; yes.. check banks
	sec
	sbc #1				; dec bank
	sta mmu
	jmp r0bnklp
; check bank no
	; .a already 0
r0bchk:	sta pointer			; RAM0 start $0400
	; .a = start bank 0
r0chklp:ldx #$04
	stx pointer+1
	ldy #0
	sty temp			; clear test flag (0=ok)
r0bchlp:cmp (pointer),y
	beq r0chknx			; ok
	ldx #$80
	stx temp			; bad flag
r0chknx:iny
	bne r0bchlp			; next byte
	inc pointer+1			; inc page
	ldx pointer+1
	cpx #$80			; finished RAM0?
	bne r0bchlp			; no.. next page

	bit temp			; bank ok?
	bpl r0chkok			; yes.. skip line
	tay				; remember bank
	jsr TestBAD
	tya
	jmp r0chnxb			; skip
r0chkok:tay				; remember bank
	jsr SetResultPointer		; skip line
	tya
; increase bank
r0chnxb:cmp #$0f			; last bank?
	beq rstmmu
	clc
	adc #1				; inc bank
	sta mmu
	jmp r0chklp			; check next bank

rstmmu:	lda #$00
	sta mmu

	ldx #<(Screen+4*COLS+29)		; reset to first result screen position
	stx result_pointer 
	ldx #>(Screen+4*COLS+29)
	stx result_pointer+1

	jmp tstram1			; continue with test of RAM1 above stack
; -------------------------------------------------------------------------------------------------
; write OK
TestOK:	jsr SetResultPointer
	lda #'O'
	sta VDPRamWrite
	+VdpWait WAITVRAM,5-1
	lda #'K'
	sta VDPRamWrite
	rts
; -------------------------------------------------------------------------------------------------
; write BAD
TestBAD:jsr SetResultPointer
	lda #'B'
	sta VDPRamWrite
	+VdpWait WAITVRAM,5-1
	lda #'A'
	sta VDPRamWrite
	+VdpWait WAITVRAM,5-1
	lda #'D'
	sta VDPRamWrite
	rts
; ******************************************** STACK **********************************************
!zone stack
*= $01e0
; only small stack used
; ******************************************** CODE2 **********************************************
!zone code2
*= $0200
tstram1:lda #0
	sta temp			; clear test flag (0=ok)
; TEST $00, $ff
	+st16i pointer, $8000		; ramtest start
	ldy #0
r1tst00:lda #$00			; test byte $00
	sta (pointer),y
	cmp (pointer),y
	beq r1tstff			; ok
	lda #$80
	sta temp			; bad flag
r1tstff:lda #$ff			; test byte $ff
	sta (pointer),y
	cmp (pointer),y
	beq r1t00nx			; ok
	lda #$80
	sta temp			; bad flag
r1t00nx:iny
	bne r1tst00			; next byte
	inc pointer+1			; inc page
	lda pointer+1
	beq r1ini5a			; $0000 -> test finished
	cmp #$dc			; I/O area reached?
	bne r1tst00			; no.. next page
	lda #$e0			; skip I/O
	sta pointer+1
	bne r1tst00			; always: next page behind I/O
; TEST $5a, $a5
r1ini5a:+st16i pointer, $8000		; ramtest start
	; .y already 0
r1tst5a:lda #$5a			; test byte $5a
	sta (pointer),y
	cmp (pointer),y
	beq r1tsta5			; ok
	lda #$80
	sta temp			; bad flag
r1tsta5:lda #$a5			; test byte $a5
	sta (pointer),y
	cmp (pointer),y
	beq r1t5anx			; ok
	lda #$80
	sta temp			; bad flag
r1t5anx:iny
	bne r1tst5a			; next byte
	inc pointer+1			; inc page
	lda pointer+1
	beq r1iniaa			; $0000 -> test finished
	cmp #$dc			; I/O area reached?
	bne r1tst5a			; no.. next page
	lda #$e0			; skip I/O
	sta pointer+1
	bne r1tst5a			; always: next page behind I/O
; TEST $aa, second byte $55
r1iniaa:+st16i pointer, $8000		; ramtest start
	; .y already 0
r1tstaa:lda #$aa			; test 1.byte $aa
	sta (pointer),y
	iny
	lda #$55			; test 2.byte $55
	sta (pointer),y
	dey
	lda (pointer),y
	cmp #$aa
	beq r1tst55			; ok
	lda #$80
	sta temp			; bad flag
r1tst55:iny
	lda (pointer),y
	cmp #$55
	beq r1taanx			; ok
	lda #$80
	sta temp			; bad flag
r1taanx:iny
	bne r1tstaa			; next byte
	inc pointer+1			; inc page
	lda pointer+1
	beq r1inilo			; $0000 -> test finished
	cmp #$dc			; I/O area reached?
	bne r1tstaa			; no.. next page
	lda #$e0			; skip I/O
	sta pointer+1
	bne r1tstaa			; always: next page behind I/O
; TEST address lowbyte
r1inilo:+st16i pointer, $8000		; ramtest start
	; .y already 0
r1tstlo:tya				; store address lowbyte
	sta (pointer),y
	iny
	bne r1tstlo			; next byte
	inc pointer+1			; inc page
	lda pointer+1
	beq r1inilc			; $0000 -> test finished
	cmp #$dc			; I/O area reached?
	bne r1tstlo			; no.. next page
	lda #$e0			; skip I/O
	sta pointer+1
	bne r1tstlo			; always: next page behind I/O
r1inilc	+st16i pointer, $8000		; ramtest start
	; .y already 0
r1chklo:tya				; check address lowbyte
	cmp (pointer),y
	beq r1tlonx			; ok
	lda #$80
	sta temp			; bad flag
r1tlonx:iny
	bne r1chklo			; next byte
	inc pointer+1			; inc page
	lda pointer+1
	beq r1inihi			; $0000 -> test finished
	cmp #$dc			; I/O area reached?
	bne r1chklo			; no.. next page
	lda #$e0			; skip I/O
	sta pointer+1
	bne r1chklo			; always: next page behind I/O
; TEST address highbyte
r1inihi:+st16i pointer, $8000		; ramtest start
	; .y already 0, address highbyte already in .a
r1tsthi:sta (pointer),y
	iny
	bne r1tsthi			; next byte
	inc pointer+1			; inc page
	lda pointer+1
	beq r1inihc			; $0000 -> test finished
	cmp #$dc			; I/O area reached?
	bne r1tsthi			; no.. next page
	lda #$e0			; skip I/O
	sta pointer+1
	bne r1tsthi			; always: next page behind I/O
r1inihc:+st16i pointer, $8000		; ramtest start
	; .y already 0, address highbyte already in .a
r1chkhi:cmp (pointer),y
	beq r1thinx			; ok
	lda #$80
	sta temp			; bad flag
r1thinx:iny
	bne r1chkhi			; next byte
	inc pointer+1			; inc page
	lda pointer+1
	beq r1reslt			; $0000 -> test finished
	cmp #$dc			; I/O area reached?
	bne r1chkhi			; no.. next page
	lda #$e0			; skip I/O
	sta pointer+1
	bne r1chkhi			; always: next page behind I/O
; print result
r1reslt:bit temp			; bank ok?
	bpl ram1ok			; yes.. print ok
	jsr TestBAD
	jmp r1nxbnk			; next bank

ram1ok:	jsr TestOK
; next bank
r1nxbnk:lda mmu
	cmp #$f0			; last bank?
	beq r1bnkst
	clc
	adc #$10			; inc bank
	sta mmu
	jmp tstram1			; test next bank
; store bank no
	; last bank in .a
r1bnkst:ldx #<(Screen+4*COLS+29)		; reset to first result screen position
	stx result_pointer 
	ldx #>(Screen+4*COLS+29)
	stx result_pointer+1

	ldx #$00			; RAM1 start $8000
	stx pointer
r1bnklp:ldx #$80
	stx pointer+1
	ldy #0
r1bstlp:sta (pointer),y
	iny
	bne r1bstlp			; next byte
	inc pointer+1			; inc page
	ldx pointer+1
	beq r1bstdc			; $0000 -> test finished
	cpx #$dc			; I/O area reached?
	bne r1bstlp			; no.. next page
	ldx #$e0			; skip I/O
	stx pointer+1
	bne r1bstlp			; always: next page behind I/O
; decrease bank
r1bstdc:cmp #$00			; first bank reached?
	beq r1bchk			; yes.. check banks
	sec
	sbc #$10			; dec bank
	sta mmu
	jmp r1bnklp
; check bank no
	; .a already 0
r1bchk:	sta pointer			; RAM1 start $8000
	; .a = start bank 0
r1chklp:ldx #$80
	stx pointer+1
	ldy #0
	sty temp			; clear test flag (0=ok)
r1bchlp:cmp (pointer),y
	beq r1chknx			; ok
	ldx #$80
	stx temp			; bad flag
r1chknx:iny
	bne r1bchlp			; next byte
	inc pointer+1			; inc page
	ldx pointer+1
	beq r1bkres			; $0000 -> test finished
	cpx #$dc			; I/O area reached?
	bne r1bchlp			; no.. next page
	ldx #$e0			; skip I/O
	stx pointer+1
	bne r1bchlp			; always: next page behind I/O

r1bkres:bit temp			; bank ok?
	bpl r1chkok			; yes.. skip line
	tay				; remember bank
	jsr TestBAD
	tya
	jmp r1chnxb			; skip
r1chkok:tay				; remember bank
	jsr SetResultPointer		; skip line
	tya
; increase bank
r1chnxb:cmp #$f0			; last bank?
	beq end				; end
	clc
	adc #$10			; inc bank
	sta mmu
	jmp r1chklp			; check next bank

end:	lda #$00
	sta mmu
	jmp Test			; restart with RAM0
; -------------------------------------------------------------------------------------------------
; set and move result pointer
SetResultPointer:
	ldx result_pointer		; screen pointer to result
	lda result_pointer+1
	+VdpWriteAddress
	txa				; low to .a
	clc
	adc #COLS			; result pointer to next line
	sta result_pointer
	bcc setrptx
	inc result_pointer+1
	+VdpWait WAITVRAM1,21-1
setrptx:rts
; ******************************************** BASIC **********************************************
!zone basic
*= $0400
