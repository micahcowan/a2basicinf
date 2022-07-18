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
HIMEM  = $73
PRGEND = $AF

GARBAGE = $E484

CROUT= $FD8E
COUT = $FDED
PRNTAX=$F941

.macpack apple2

.macro mPrintSubtraction arg1, arg2, saveSpot
	jsr PrintImmediate
        scrcode .string(arg1)
        .repeat 7 - .strlen(.string(arg1))
        scrcode " "
        .endrepeat
        scrcode "("
        .byte 0
        ldy #arg1
        jsr PrintZpHexY
	jsr PrintImmediate
        scrcode ") - "
        scrcode .string(arg2)
        scrcode " ("
        .byte 0
        ldy #arg2
        jsr PrintZpHexY
	jsr PrintImmediate
        scrcode ") = $"
        .byte 0
        lda arg1
        sec
        sbc arg2
        tax
        lda arg1+1
        sbc arg2+1
.ifnblank saveSpot
	stx saveSpot
        sta saveSpot+1
.endif
        jsr PRNTAX
        jsr CROUT
.endmacro

.segment "BASICINF"

BasicInf:
	jsr CROUT
	mPrintSubtraction PRGEND, TXTTAB
        lda #0
        sta looped
        mPrintSubtraction STREND, VARTAB, addOne
@loop:
        mPrintSubtraction HIMEM, FRETOP, addTwo
        jsr PrintSum
        lda looped
        bne @afterLoop
        jsr PrintImmediate
        scrcode "- AFTER RUNNING GARBAGE COLLECT -", $0D
        .byte 0
        lda #1
        sta looped
        jsr GARBAGE
        jmp @loop
@afterLoop:
        jsr CROUT
.ifndef EXITTODOS
        rts
        nop
        nop
.else
	jmp $3D0
.endif

addOne:
	.word 0
addTwo:
	.word 0
looped:
	.byte 0

PrintSum:
	jsr PrintImmediate
        scrcode "  $"
        .byte 0
        ldx addOne
        lda addOne+1
        jsr PRNTAX
        jsr PrintImmediate
        scrcode " + $"
        .byte 0
        ldx addTwo
        lda addTwo+1
        jsr PRNTAX
        jsr PrintImmediate
        scrcode " = $"
        .byte 0
        lda addOne
        clc
        adc addTwo
        tax
        lda addOne+1
        adc addTwo+1
        jsr PRNTAX
        jsr CROUT
	rts

PrintZpHexY:
	lda #$A4
        jsr COUT
	ldx $0,y
        lda $1,y
        jsr PRNTAX
	rts

; Print a NUL-term'd string that occurs IMMEDIATELY after
; the call to this subroutine, and return wpast it.
PrintImmediate:
	clc
	pla
        adc #1
        sta ARGPTR
        pla
        adc #0
        sta ARGPTR+1
        jsr PrintMessage
        lda ARGPTR+1
        pha
        lda ARGPTR
        pha
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