.import LoadAndRunBasic

.segment "STARTUP"
Startup:
	ldx #$FF
        txs
        jmp LoadAndRunBasic
        brk