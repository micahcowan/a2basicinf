;#link "basicinf-startup.s"
;#link "load-and-run-basic.s"
;#link "basicinf-basic.s"

;#resource "apple2.rom"

;#resource "basicinf.cfg"
;#define CFGFILE basicinf.cfg

ARGPTR = $6

COUT = $FDED

.macpack apple2

.segment "BASICINF"

BasicInf:
	lda #<message
        sta ARGPTR
        lda #>message
        sta ARGPTR+1
	jmp PrintMessage
PrMsgNextChar:
	inc ARGPTR
        bne PrintMessage
        inc ARGPTR
PrintMessage:
	ldy #0
	lda (ARGPTR),y
        jsr COUT
        cmp #$8D
        bne PrMsgNextChar
        rts
message:
	scrcode "HELLO, WORLD!", $0D