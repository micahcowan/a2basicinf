all: BASICINF.DSK

BASICINF.DSK: HELLO BASICINF
	rm -f $@
	cp empty.dsk $@
	dos33 -y $@ SAVE A HELLO
	dos33 -y -a 0x6000 $@ BSAVE BASICINF

HELLO: hello-basic.txt Makefile
	tokenize_asoft < $< > $@ || { rm $@; exit 1; }

BASICINF: basicinf.o
	ld65 --config build.cfg -o $@ basicinf.o

.SECONDARY: basicinf.o
basicinf.o: basicinf.s Makefile
	ca65 -D EXITTODOS --listing basicinf.list basicinf.s

clean:
	rm -f HELLO BASICINF BASICINF.DSK basicinf.o basicinf.list
