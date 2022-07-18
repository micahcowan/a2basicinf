.macpack apple2

.export ASoftProg, ASoftEnd

LINE_NUMBER .set 10

.macro line arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9
scrcode .concat(.sprintf("%d ", LINE_NUMBER),arg1), arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9
LINE_NUMBER .set LINE_NUMBER+10
.endmacro

ASoftProg:
line "I = 1:J = 0",$0D
line "DIM N%(16)",$0D
line "FOR I = 1 TO 16",$0D
line "N%(I) = I",$0D
line "NEXT",$0D
line "DIM S$(10)",$0D
line "FOR J = 0 TO 10",$0D
line "READ S$(J)",$0D
line "S$(J) = ",'"',":",'"'," + S$(J) + ",'"',":",'"',$0D
line "NEXT",$0D
line "? ",'"',"DONE TROMPING AROUND MEMORY.",'"',$0D
line "DATA  ZERO,ONE,TWO,THREE,FOUR,FIVE",$0D
line "DATA  SIX,SEVEN,EIGHT,NINE,TEN",$0D

scrcode "RUN",$0D

scrcode "CALL 24576",$0D

ASoftEnd:
