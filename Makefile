PLAT= none

all:  $(PLAT)

PLATS= linux mingw

none:
	@echo "Please do 'make PLATFORM' where PLATFORM is one of these:"
	@echo "   $(PLATS)"

linux: remotedebug.so

mingw: remotedebug.dll

remotedebug.so: remotedebug.c debugvar.h
	gcc -Wall -g --shared -o $@ $< -I/usr/local/include -L/usr/local/bin -llua -fPIC

remotedebug.dll : remotedebug.c debugvar.h
		gcc -Wall -g --shared -o $@ $< -I/usr/local/include -L/usr/local/bin -llua53

clean :
	rm remotedebug.so
	rm remotedebug.dll
