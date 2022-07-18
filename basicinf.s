;#link "basicinf-startup.s"
;#link "load-and-run-basic.s"
;#link "basicinf-basic.s"

;#resource "apple2.rom"

;#resource "basicinf.cfg"
;#define CFGFILE basicinf.cfg

ARGPTR = $6

CURSH = $24

TXTTAB = $67
VARTAB = $69
ARYTAB = $6B
STREND = $6D
FRETOP = $6F
MEMSIZE= $73
PRGEND = $AF

CROUT= $FD8E
COUT = $FDED
PRNTAX=$F941

.macpack apple2

.macro mPrintMessageAndVal msg, val
	lda #<msg
        sta ARGPTR
        lda #>msg
        sta ARGPTR+1
        jsr PrintMessage
        ldy #val
        jsr PrintWord
.endmacro

.segment "BASICINF"

BasicInf:
	jsr CROUT
	mPrintMessageAndVal msgTxttab, TXTTAB
        mPrintMessageAndVal msgPrgend, PRGEND
.ifndef EXITTODOS
        rts
        nop
        nop
.else
	jmp $3D0
.endif

msgTxttab:
	scrcode "START OF PROG (TXTTAB) IS"
        .byte $0
msgPrgend:
        scrcode "END OF PROG (PRGEND) IS"
        .byte $0
msgProgSz:
	scrcode "PROGRAM CODE SIZE IS"
        .byte $0

msgVartab:
        scrcode "START OF VARS (VARTAB) IS"
        .byte $0
msgStrend:
	scrcode "END OF VARS (STREND) IS"
        .byte $0
msgVarSz:
	scrcode "VAR NAMES/ARRAYS SIZE IS"
        .byte $0

msgHimem:
        scrcode "END OF DATA (HIMEM) IS"
        .byte $0
msgFretop:
	scrcode "STRING SPACE USED DOWN TO (FRETOP)"
        .byte $0
msgStrSz:
	scrcode "STRINGS USED SPACE IS"
        .byte $0
msgDataSz:
	scrcode "TOTAL VAR/STR SIZE IS"
        .byte $0

; Word to be printed is in $0,y
PrintWord:
        lda #27
        sta CURSH
        lda #$A4
        jsr COUT
	lda $0,y
        sta ARGPTR
        iny
        lda $0,y
        sta ARGPTR+1
        ldx ARGPTR
        jsr PRNTAX
        
        lda #$A0
        jsr COUT
        lda #$A8
        jsr COUT
        ldy ARGPTR
        lda ARGPTR+1
        jsr prDec16u_AY
        lda #$A9
        jsr COUT
        jsr CROUT
        rts
        
PrintMessage:
	ldy #0
@SkipLDY:
	lda (ARGPTR),y
        beq @Done
        jsr COUT
        inc ARGPTR
        bne @SkipLDY
        inc ARGPTR+1
        bne @SkipLDY
@Done:
	rts

div10w_AY:
    ; initialize vars
    sta dividendH
    sty dividendL
    lda #0
    sta quotientL
    sta quotientH
    sta markerL
    sta divisorL
    lda #$A0
    sta divisorH
    lda #$10
    sta markerH
@Lp:
    lda dividendH
    bne @NotZero
    lda divisorH
    beq @divHZero ; skip high bytes if we're past that
    lda dividendH
@NotZero:
    cmp divisorH
    beq @CheckLow ; divisorH == dividendH? check low byte too
    bcs @Mk       ; divisorH < dividendH? divide!
    ; otherwise shift dividend and marker right and try again
@shiftR:
    lsr divisorH
    ror divisorL
    lsr markerH
    ror markerL ; we'd do a carry check after, but
                ; for 10 we know that only happens
                ; when we're down to low bytes
    jmp @Lp
    ; We need to check divisorL <= dividendL too
@CheckLow:
    lda dividendL
    cmp divisorL
    bcc @shiftR
@Mk:
    lda dividendL
    sec
    sbc divisorL
    sta dividendL
    lda dividendH
    sbc divisorH
    sta dividendH
    lda markerH
    ora quotientH
    sta quotientH
    lda markerL
    ora quotientL
    sta quotientL
    jmp @shiftR
@divHZero:
    ; with some prep code before, could jump here for an
    ; 8-bit division...
    lda dividendL
    cmp divisorL
    bcs @Mk8 ; divisorL
    ; shift dividend and marker
@shiftR8:
    lsr divisorL
    lsr markerL
    bcc @divHZero
    ; carry is set - we shifted off the end!
    ; set A and Y according to the result
    lda quotientH
    ldy quotientL
    ldx dividendL ; remainder/modulus
    rts
@Mk8:
    lda dividendL
    sec
    sbc divisorL
    sta dividendL
    lda markerL
    ora quotientL
    sta quotientL
    jmp @shiftR8
dividendL:
    .byte $00
dividendH:
    .byte $00
quotientL:
    .byte $FF
quotientH:
    .byte $FF
markerL:
    .byte $FF
markerH:
    .byte $FF
divisorL:
    .byte $FF
divisorH:
    .byte $FF
    
prDec16u_AY:
    ; push X onto stack while preserving A (no PHX for 6502)
    ldx #$00
    stx saveIdx
@loop:
    ; divide A Y by 10
    jsr div10w_AY
    sta saveA ; preserve answer
    stx saveX
    lda saveIdx
    tax
    lda saveX
    ora #$B0
    sta digits, x ; store modulus in digits
    lda saveA
    ; if the division result is 0 then we're done
    bne @loopNext
    cpy #0
    beq @done
@loopNext:
    ; quotient !+ 0, we're not done. Increment and loop back!
    inx
    stx saveIdx
    bne @loop
@done:
    lda digits,x
    jsr COUT
    dex
    bpl @done
@rts:
    rts
saveX:
    .byte 0
saveA:
    .byte 0
saveIdx:
    .byte 0
digits:
    .byte 0,0,0,0,0
digitsEnd: