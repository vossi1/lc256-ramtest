; LC256 Ramtest
; for ACME assembling by Vossi 11/2024, last update 11/2024
; v1.0 initial - special pcb v.1.0 128K-version
!cpu 65c02	; 6502, 6510, 65c02, 65816
!ct scr		; Standard text/char conversion table -> pet = petscii
!to "ramtest", cbm
!source "defines.b"
!source "macros.b"
; **************************************** BASIC LOADER *******************************************
!initmem FILL
!zone basic
*= $0401
!byte $0c,$04,$0a,$00,$9e,$20,$31,$30,$33,$38,$00,$00,$00	; 10 SYS 1038
; ***************************************** ZONE MAIN *********************************************
!zone main
*= $040e
; main code
	sei
	jsr VdpInit			; init VDP
	jsr VdpClear			; clear screen
	jsr VdpOn			; switch display on
; screen
	+st16i pointer, S_Title		; string address
	ldy #0				; line in .y
	ldx #0				; column in .x
	jsr VdpText			; write string
	+st16i pointer, S_Rams
	ldy #2
	ldx #0
	jsr VdpText
	+st16i pointer, S_Tests
	ldy #22
	ldx #0
	jsr VdpText
	
	ldy #4
	sty counter			; bank line
wbnklp:	+st16i pointer, S_Bank		; string address
	ldy counter			; line
	ldx #0				; column
	jsr VdpText
	lda counter 
	clc
	adc #'0'-4			; calc screencode (-line)
	cmp #'9'+1
	bcc wbnkno			; 0-9 -> skip
	clc
	adc #7				; a-f
wbnkno:	sta S_No			; store in dummy string
	ldy counter
	ldx #5				; column left
	+st16i pointer, S_No		; Dummy string address
	jsr VdpText
	ldy counter
	ldx #5+20			; column right
	+st16i pointer, S_No
	jsr VdpText
	inc counter
	lda counter
	cmp #4+4			; last bank?
	bne wbnklp			; ..no -> next line
; copy TESTCODE
	lda #<TestCode			; testcode source
	sta source_pointer
	lda #>TestCode
	sta source_pointer+1
	lda #<TESTCODE			; target
	sta pointer
	lda #>TESTCODE
	sta pointer+1
	ldy #0
	
copylp:	lda (source_pointer),y
	sta (pointer),y
	iny
	bne copylp
	inc source_pointer+1
	inc pointer+1
	lda pointer+1
	cmp #$04			; reached basic start?
	bne copylp			; no.. copy next page

; disable ROM
	lda  #%11011100         ; via2: ca2 low, cb2 low, ca1 neg,cb1 pos
	sta  via2+pcr		;   MMU: ca2+cb2 = ROM disabled, ca1 = restore key

	jmp TESTCODE
; *********************************** ZONE VDP SUBROUTINES ****************************************
!zone vdp_subroutines
; init vdp
VdpInit:lda #0
	tax
	+VdpSetReg 17			; write VDP regs fast indirect
	+VdpWait WAIT23,7-1
vinilp:	lda VdpInitData,x
	sta VDPIndirect
	inx
	cpx #VdpInitDataEnd-VdpInitData
	+VdpWait WAIT23,14
	bne vinilp
	
	lda #VDPREG18
	+VdpWait WAIT23,11-1
	+VdpSetReg 18			; set register 18 V/H display adjust L 7-1,0,f-8 R
; clear 16kB VRAM
	lda #$00
	tax
	+VdpWait WAIT23,7-1
	+VdpWriteAddress		; set VRAM write address to $aaxx = $0000, Bank Reg already 0
	; .x still 0
	txa				; VRAM init value =$00
	ldy #$40			; $40 pages to clear = 16kB
	+VdpWait WAITVRAM1,7-1
viramlp:sta VDPRamWrite
	inx
	+VdpWait WAITVRAM,9-1
	bne viramlp
	dey				; next page
	bne viramlp			; continue till finished
	; .y already 0
	tya				; .a=0
	+VdpWait WAIT23,11-1	
	+VdpSetReg 14			; set VRAM bank register to 0
; copy color palette
	; .x.y already 0
	tya				; .a=0
	+VdpSetReg 16			; set VDP register 16 = palette pointer to 0 
	+VdpWait WAIT23,7-1	
vipallp:lda PaletteData,x		; load palette-color to write
	sta VDPPalette
	inx
	cpx #PaletteDataEnd-PaletteData	; finished ?
	+VdpWait WAIT23,14	
	bne vipallp			; ..no -> next color
; copy font to pattern generator table
	lda #>PatternTable
	ldx #<PatternTable
	+VdpWait WAIT23,13-1
	+VdpWriteAddress		; set VRAM write address to $aaxx = PatternTable
	+st16i pointer, FontData	; set pointer to fontdata 
	ldx #FONTPAGES			; pages to copy
	; .y already 0
	+VdpWait WAITVRAM1,20
vifntlp:lda (pointer),y			; load data
	sta VDPRamWrite
	iny
	+VdpWait WAITVRAM,13-1
	bne vifntlp
	inc pointer+1			; inc fontdata pointer hi
	dex				; next page
	bne vifntlp			; continue till finished
	rts
; -------------------------------------------------------------------------------------------------
; enable screen
VdpOn:	lda # VDPREG1 | $40		; set mode reg 1 (M1+M2), bit#6 = 1 enables screen
	+VdpSetReg 1
	rts
; -------------------------------------------------------------------------------------------------
; clear screen
VdpClear:
	ldx #<Screen
	lda #>Screen
	+VdpWriteAddress		; set VRAM write address to $aaxx = Screen
	ldx #<(ROWS*COLS)		; .y.x = bytes to clear
	ldy #>(ROWS*COLS)
	lda #' '			; space
	+VdpWait WAITVRAM1,9-1
vclrlp:	sta VDPRamWrite
	dex				; dec lo
	+VdpWait WAITVRAM,8
	bne vclrlp
	dey				; dec hi
	bpl vclrlp			; continue till finished
	rts
; -------------------------------------------------------------------------------------------------
; copy string=pointer to column x, row y
VdpText:
	stx temp			; safe column
	lda #<Screen			; .x.a = screen table base
	ldx #>Screen
vtrowlp:cpy #0
	beq vtcols			; line calc finished
	dey
	clc
	adc #COLS			; add line columns
	bcc vtrowlp			; next line
	inx
	bcs vtrowlp			; always next line
vtcols:	clc
	adc temp			; add column
	bcc vtadr			; no carry
	inx				; inc hi
vtadr:	stx temp			; exchange .x.a
	tax
	lda temp
	+VdpWriteAddress
	+VdpWait WAITVRAM1,12
vtwrite:lda (pointer),y			; get char
	cmp #V_NULL			; end of string?
	beq vtexit			; ..yes -> exit
	sta VDPRamWrite
	+VdpWait WAITVRAM,17-1
	iny				; next character from string
	bne vtwrite
vtexit	rts
; ****************************************** ZONE DATA ********************************************
!zone data
S_Title	!scr "LC256 Ramtest v.1.0 (c) 2024 Vossi", V_NULL
S_Rams	!scr "RAM0 (0000-7FFF)    RAM1 (8000-FFFF)", V_NULL
S_Bank	!scr "Bank                Bank", V_NULL
S_No	!scr "0", V_NULL		; Dummy Bank no
S_Tests	!scr "Test runs in KB0, skips I/O DC00-DFFF", V_NULL
; -------------------------------------------------------------------------------------------------
VdpInitData:				; text mode 1 40x24
!byte $00,VDPREG1,$00,$1f,$01,$3f,$03,COLOR*16+BGRCOLOR,$08,VDPREG9,$00,$00,$00,$f0,$00
	; reg  0: $00 mode control 1: text mode 1 (bit#1-3 = M3 - M5)
	; reg  1: $10 mode control 2: bit#1 16x16 sprites, bit#3-4 = M2-M1, #6 =1: display enable)
	; reg  2: $00 name (screen) table base address $0000 ( * $100)
	; reg  3: $1f color table base address $0600 ( * $40 + bit#0-2 = 1)
	; reg  4: $01 pattern (character) generator table base address $0800 (* $800)
	; reg  5: $3f sprite attribute table base address $1e00 (* $80 - bit#0+1 = 1)
	; reg  6: $03 sprite pattern (data) generator base address = $1800 (* $800)
	; reg  7: $60 text/overscan-backdrop color
	; reg  8: $08 bit#3 = 1: 64k VRAM chips, bit#1 = 0 sprites disable, bit#5 0=transparent
	; reg  9: $80 bit#1 = NTSC/PAL, #2 = EVEN/ODD, #3 = interlace, #7 = 192/212 lines
	; reg 10: $00 color table base address $0000 bit#0-2 = A14-A16
	; reg 11: $00 sprite attribute table base address bit#0-1 = A15-A16
	; reg 12: $00 text/background blink color
	; reg 13: $f0 blink periods ON/OFF - f0 = blinking off
	; reg 14: $00 VRAM write addresss bit#0-2 = A14-A16
VdpInitDataEnd:
; -------------------------------------------------------------------------------------------------
; ***** Color Palette - 16 colors, 2 byte/color: RB, 0G each 3bit -> C64 VICII-colors *****
PaletteData:
	!byte $00,$00,$77,$07,$70,$01,$17,$06	;	0=black		1=white		2=red		3=cyan
	!byte $56,$02,$32,$06,$06,$02,$72,$07	;	4=violet	5=green		6=blue		7=yellow
	!byte $70,$03,$60,$02,$72,$03,$11,$01	;	8=orange	9=brown		a=lightred	b=darkgrey
	!byte $33,$03,$54,$07,$27,$04,$55,$05	;	c=grey		d=litegreen	e=lightblue	f=lightgrey
PaletteDataEnd:
; ******************************************** TEST ***********************************************
; test code binary
!zone test
TestCode:
!binary "test.bin"
; ******************************************** FONT ***********************************************
; font 256 chars 6x8
!zone font
FontData:
!binary "c64-6x8.fon"
