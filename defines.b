; LC256 Ramtest Defines
; for ACME assembling by Vossi 11/2024, last update 11/2024
; v1.0 initial
; switches
CLOCK = 4		; CPU clock in MHz for VDP waits
; vdp
PAL = 1			; PAL=1, NTSC=0		selects V9938/58 PAL RGB-output, NTSC has a higher picture
; VDP speed parameter - don't change!
WAIT12 = 1 ; 2		; us 1. - 2. byte VDP
WAIT23 = 2 ; 5		; us 2. - 3. byte VDP
WAITVRAM1 = 3		; us vram 1.access
WAITVRAM = 6		; us vram loop (text mode 1+2: 6, mode 6+7: 5)
; ***************************************** CONSTANTS *********************************************
FILL		= $00		; fills free memory areas with $00
V_NULL		= $ff		; VDP string End
; colors
BLUE		= 6
WHITE		= 1
; VDP defines
VDPREG1         = $10           ; VDP reg 1 value (mode bits M1+M2, screen disabled)
VDPREG9         = $00 | PAL*2   ; VDP reg 9 value ($00 = NTSC, $02 = PAL / 192 lines)
VDPREG18        = $0d           ; VDP reg 18 value (V/H screen adjust, $0d = Sony PVM 9")
FONTPAGES	= $08		; fontdata size in pages
; colors
COLOR		= WHITE
BGRCOLOR	= BLUE
; screen values
COLS		= 40		; screen columns
ROWS		= 24		; used lines
; ***************************************** ADDRESSES *********************************************
; I/O addresses
VDPWriteAdr	= $dc00		; Port#0 RamWrite, #1 Control, #2 Palette, #3 Indirect
VDPReadAdr	= $dc80		; Port#0 RamRead, #1 Status
; VDP ports
!addr	VDPRamWrite	= VDPWriteAdr
!addr	VDPControl	= VDPWriteAdr+1
!addr	VDPPalette	= VDPWriteAdr+2
!addr	VDPIndirect	= VDPWriteAdr+3
!addr	VDPRamRead	= VDPReadAdr
!addr	VDPStatus	= VDPReadAdr+1
PatternTable		= $0800		; font
Screen			= $0000
; 6522 VIA2 - MMU, IEC, USB RXF/TXE, Restore
	prb	= $0		; Port reg b
	pcr	= $c		; peripheral control register
!addr	via2	= $de40
!addr	mmu	= via2+prb	; VIA2 port B MMU register
; ***************************************** ZERO PAGE *********************************************
; Variables
*=$0000
!addr	result_pointer			; pointer to result screen position
!addr	source_pointer	*=*+2		; pointer for code copy 
!addr	temp		*=*+1		; temp
!addr	counter		*=*+1		; counter
!addr	pointer		*=*+2		; pointer
!addr	TESTCODE	=*		; start of testcode
