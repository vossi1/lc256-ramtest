; LC256 Ramtest Macros
; for ACME assembling by Vossi 11/2024, last update 11/2024
; v1.0 initial
; ******************************************* MACROS **********************************************
!macro inc16 .a{		; *** increase 16bit
	inc .a
	bne .j
	inc .a+1
.j}
!macro st16i .a, .v{		; *** store 16bit immediate to address
	lda # <.v
	sta .a
	lda # >.v
	sta .a+1
}
; VDP macros
!macro VdpWait .u, .c{		; *** us wait - cycles already present - for VDP access
	!set .t = (.u*10-(.c*10/CLOCK))*CLOCK/20
	!do while .t > 0{
		nop			; each nop needs 2 cycles
		!set .t = .t -1}
}
!macro VdpSetReg .r{		; *** set VDP Register
	sta VDPControl			; first writes data in A to control port #1
	lda #.r | $80			; writes register no. with bit#7 = 1 to Port #1
	+VdpWait WAIT12,5-1
	sta VDPControl
}
!macro VdpWriteAddress{		; *** set VDP write vram address-pointer to AAXX
	stx VDPControl
	ora #$40			; bit#6 = 1 write
	+VdpWait WAIT12,5-1
	sta VDPControl
} 